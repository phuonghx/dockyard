#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Dockyard engine helper.

A tiny, dependency-free bridge between the Dockyard widget and the Docker /
Podman Engine API. It talks HTTP over the engine's unix socket, so it needs
neither the docker CLI nor curl, and it always prints exactly one JSON
document on stdout (errors included) so the widget never has to guess.

    dockyard.py [--socket PATH|auto] <command> [args]

    snapshot            containers (+ live CPU / memory), images, volumes, networks
    df                  disk usage and what is reclaimable
    act ACTION ID...    start | stop | restart | pause | unpause | kill | rm
    rmi ID | rmvol NAME | rmnet ID
    prune WHAT          containers | images | images-all | volumes | builder
    logs ID [TAIL]      last TAIL lines (default 200), ANSI stripped
    inspect ID          the bits worth showing in the drawer
"""
from __future__ import annotations

import argparse
import http.client
import json
import os
import re
import socket
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from urllib.parse import quote

ANSI = re.compile(r"\x1b\[[0-9;?]*[ -/]*[@-~]")
MAX_LOG_BYTES = 256 * 1024


class EngineError(Exception):
    def __init__(self, kind: str, message: str, hint: str = ""):
        super().__init__(message)
        self.kind, self.message, self.hint = kind, message, hint


class _UnixConnection(http.client.HTTPConnection):
    def __init__(self, path: str, timeout: float):
        super().__init__("localhost", timeout=timeout)
        self._path = path

    def connect(self) -> None:
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.settimeout(self.timeout)
        s.connect(self._path)
        self.sock = s


class Engine:
    def __init__(self, path: str):
        self.path = path

    def request(self, method: str, url: str, body=None, timeout: float = 20.0):
        conn = _UnixConnection(self.path, timeout)
        try:
            headers = {"Host": "dockyard"}
            data = None
            if body is not None:
                data = json.dumps(body)
                headers["Content-Type"] = "application/json"
            conn.request(method, url, body=data, headers=headers)
            resp = conn.getresponse()
            return resp.status, resp.read()
        finally:
            conn.close()

    def call(self, method: str, url: str, ok=(200,), **kw):
        status, raw = self.request(method, url, **kw)
        if status not in ok:
            raise EngineError("api", _api_message(raw) or f"HTTP {status}")
        if not raw:
            return None
        try:
            return json.loads(raw)
        except ValueError:
            return raw


def _api_message(raw: bytes) -> str:
    try:
        return str(json.loads(raw).get("message", "")).strip()
    except Exception:
        return raw.decode("utf-8", "replace").strip()[:300]


def candidate_sockets(explicit: str | None) -> list[str]:
    if explicit and explicit != "auto":
        return [explicit.removeprefix("unix://")]
    runtime = os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}"
    found: list[str] = []
    host = os.environ.get("DOCKER_HOST", "")
    if host.startswith("unix://"):
        found.append(host[7:])
    found += [
        "/var/run/docker.sock",
        f"{runtime}/docker.sock",
        f"{runtime}/podman/podman.sock",
        "/run/podman/podman.sock",
    ]
    seen: set[str] = set()
    return [p for p in found if not (p in seen or seen.add(p))]


def connect(explicit: str | None) -> Engine:
    last: EngineError | None = None
    for path in candidate_sockets(explicit):
        if not os.path.exists(path):
            continue
        try:
            engine = Engine(path)
            engine.request("GET", "/_ping", timeout=3)
            return engine
        except PermissionError:
            last = EngineError(
                "permission_denied",
                f"No permission to use {path}.",
                "sudo usermod -aG docker $USER   (then log out and back in)",
            )
        except (ConnectionRefusedError, FileNotFoundError, socket.timeout, OSError):
            last = last or EngineError(
                "not_running",
                f"The engine is not answering on {path}.",
                "sudo systemctl enable --now docker",
            )
    if last:
        raise last
    raise EngineError(
        "no_socket",
        "No Docker or Podman socket found.",
        "sudo dnf install docker-ce   or   systemctl --user enable --now podman.socket",
    )


# --------------------------------------------------------------------------- stats


def _stats(engine: Engine, cid: str):
    try:
        s = engine.call("GET", f"/containers/{cid}/stats?stream=false", timeout=8)
    except Exception:
        return None
    if not isinstance(s, dict):
        return None
    cpu, pre = s.get("cpu_stats") or {}, s.get("precpu_stats") or {}
    cpu_delta = (cpu.get("cpu_usage") or {}).get("total_usage", 0) - (pre.get("cpu_usage") or {}).get("total_usage", 0)
    sys_delta = (cpu.get("system_cpu_usage") or 0) - (pre.get("system_cpu_usage") or 0)
    cores = cpu.get("online_cpus") or len((cpu.get("cpu_usage") or {}).get("percpu_usage") or []) or 1
    pct = (cpu_delta / sys_delta) * cores * 100.0 if sys_delta > 0 and cpu_delta >= 0 else 0.0
    mem = s.get("memory_stats") or {}
    detail = mem.get("stats") or {}
    cache = detail.get("inactive_file", detail.get("total_inactive_file", detail.get("cache", 0)))
    used = max(0, (mem.get("usage") or 0) - (cache or 0))
    rx = tx = 0
    for n in (s.get("networks") or {}).values():
        rx += n.get("rx_bytes", 0)
        tx += n.get("tx_bytes", 0)
    return {
        "cpu": round(pct, 2),
        "mem": used,
        "memLimit": mem.get("limit") or 0,
        "netRx": rx,
        "netTx": tx,
        "pids": (s.get("pids_stats") or {}).get("current", 0),
    }


# ---------------------------------------------------------------------- snapshot


def _health(status: str) -> str:
    if "(unhealthy)" in status:
        return "unhealthy"
    if "(healthy)" in status:
        return "healthy"
    if "(health: starting)" in status:
        return "starting"
    return ""


def _ports(raw) -> list[dict]:
    seen, out = set(), []
    for p in raw or []:
        pub = p.get("PublicPort")
        if not pub:
            continue
        key = (pub, p.get("PrivatePort"), p.get("Type"))
        if key in seen:
            continue
        seen.add(key)
        out.append({"pub": pub, "priv": p.get("PrivatePort"), "proto": p.get("Type", "tcp")})
    out.sort(key=lambda x: x["pub"])
    return out


def snapshot(engine: Engine) -> dict:
    t0 = time.time()
    with ThreadPoolExecutor(max_workers=32) as pool:
        f_ver = pool.submit(engine.call, "GET", "/version")
        f_info = pool.submit(engine.call, "GET", "/info")
        f_c = pool.submit(engine.call, "GET", "/containers/json?all=1")
        f_i = pool.submit(engine.call, "GET", "/images/json")
        f_v = pool.submit(engine.call, "GET", "/volumes")
        f_n = pool.submit(engine.call, "GET", "/networks")
        raw_containers = f_c.result() or []
        stats = {c["Id"]: pool.submit(_stats, engine, c["Id"]) for c in raw_containers if c.get("State") == "running"}
        ver, info = f_ver.result() or {}, f_info.result() or {}
        raw_images, raw_vols, raw_nets = f_i.result() or [], (f_v.result() or {}).get("Volumes") or [], f_n.result() or []
        stats = {k: v.result() for k, v in stats.items()}

    vol_users: dict[str, int] = {}
    net_users: dict[str, int] = {}
    img_users: dict[str, int] = {}
    containers = []
    for c in raw_containers:
        labels = c.get("Labels") or {}
        st = stats.get(c["Id"]) or {}
        for m in c.get("Mounts") or []:
            if m.get("Type") == "volume" and m.get("Name"):
                vol_users[m["Name"]] = vol_users.get(m["Name"], 0) + 1
        for n in ((c.get("NetworkSettings") or {}).get("Networks") or {}):
            net_users[n] = net_users.get(n, 0) + 1
        img_users[c.get("ImageID", "")] = img_users.get(c.get("ImageID", ""), 0) + 1
        status = c.get("Status", "")
        containers.append(
            {
                "id": c["Id"],
                "short": c["Id"][:12],
                "name": (c.get("Names") or ["/?"])[0].lstrip("/"),
                "image": c.get("Image", ""),
                "command": c.get("Command", ""),
                "state": c.get("State", ""),
                "status": status,
                "health": _health(status),
                "created": c.get("Created", 0),
                "project": labels.get("com.docker.compose.project", ""),
                "service": labels.get("com.docker.compose.service", ""),
                "ports": _ports(c.get("Ports")),
                "cpu": st.get("cpu", 0),
                "mem": st.get("mem", 0),
                "memLimit": st.get("memLimit", 0),
                "netRx": st.get("netRx", 0),
                "netTx": st.get("netTx", 0),
                "pids": st.get("pids", 0),
            }
        )

    images = []
    for i in raw_images:
        tags = [t for t in (i.get("RepoTags") or []) if t != "<none>:<none>"]
        images.append(
            {
                "id": i["Id"],
                "short": i["Id"].removeprefix("sha256:")[:12],
                "tags": tags,
                "size": i.get("Size", 0),
                "created": i.get("Created", 0),
                "used": img_users.get(i["Id"], 0),
                "dangling": not tags,
            }
        )

    volumes = [
        {
            "id": v["Name"],
            "name": v["Name"],
            "driver": v.get("Driver", "local"),
            "created": v.get("CreatedAt", ""),
            "used": vol_users.get(v["Name"], 0),
            "anonymous": bool(re.fullmatch(r"[0-9a-f]{64}", v["Name"])),
            "project": (v.get("Labels") or {}).get("com.docker.compose.project", ""),
        }
        for v in raw_vols
    ]

    networks = [
        {
            "id": n["Id"],
            "short": n["Id"][:12],
            "name": n["Name"],
            "driver": n.get("Driver", ""),
            "scope": n.get("Scope", ""),
            "internal": bool(n.get("Internal")),
            "used": net_users.get(n["Name"], 0),
            "system": n["Name"] in ("bridge", "host", "none", "podman"),
        }
        for n in raw_nets
    ]

    components = ver.get("Components") or [{}]
    return {
        "ok": True,
        "took": round(time.time() - t0, 2),
        "engine": {
            "name": "Docker Engine" if components[0].get("Name", "Engine") == "Engine" else components[0]["Name"],
            "version": ver.get("Version", ""),
            "api": ver.get("ApiVersion", ""),
            "os": info.get("OperatingSystem", ""),
            "ncpu": info.get("NCPU", 0),
            "memTotal": info.get("MemTotal", 0),
            "rootless": any("rootless" in s for s in info.get("SecurityOptions") or []),
            "socket": engine.path,
        },
        "containers": containers,
        "images": images,
        "volumes": volumes,
        "networks": networks,
    }


def disk_usage(engine: Engine) -> dict:
    d = engine.call("GET", "/system/df", timeout=60) or {}
    images = d.get("Images") or []
    vols = d.get("Volumes") or []
    cache = d.get("BuildCache") or []
    conts = d.get("Containers") or []
    sizes = {}
    for v in vols:
        u = v.get("UsageData") or {}
        sizes[v["Name"]] = u.get("Size", -1)
    return {
        "ok": True,
        "images": sum(i.get("Size", 0) for i in images),
        "imagesReclaimable": sum(i.get("Size", 0) for i in images if not i.get("Containers")),
        "containers": sum(c.get("SizeRw", 0) or 0 for c in conts),
        "containersReclaimable": sum(c.get("SizeRw", 0) or 0 for c in conts if c.get("State") != "running"),
        "volumes": sum(max(0, s) for s in sizes.values()),
        "volumesReclaimable": sum(
            max(0, (v.get("UsageData") or {}).get("Size", 0)) for v in vols if (v.get("UsageData") or {}).get("RefCount", 1) == 0
        ),
        "cache": sum(c.get("Size", 0) for c in cache),
        "cacheReclaimable": sum(c.get("Size", 0) for c in cache if not c.get("InUse")),
        "volumeSizes": sizes,
    }


# ------------------------------------------------------------------------ actions

ACTIONS = {
    "start": ("POST", "/containers/{id}/start"),
    "stop": ("POST", "/containers/{id}/stop?t=10"),
    "restart": ("POST", "/containers/{id}/restart?t=10"),
    "pause": ("POST", "/containers/{id}/pause"),
    "unpause": ("POST", "/containers/{id}/unpause"),
    "kill": ("POST", "/containers/{id}/kill"),
    "rm": ("DELETE", "/containers/{id}?force=1&v=0"),
}


def _one(engine: Engine, method: str, url: str) -> dict:
    try:
        status, raw = engine.request(method, url, timeout=60)
    except Exception as e:  # noqa: BLE001
        return {"ok": False, "message": str(e)}
    if status in (200, 204, 304):
        return {"ok": True, "message": ""}
    return {"ok": False, "message": _api_message(raw) or f"HTTP {status}"}


def act(engine: Engine, action: str, ids: list[str]) -> dict:
    if action not in ACTIONS:
        raise EngineError("usage", f"Unknown action {action!r}")
    method, tpl = ACTIONS[action]
    with ThreadPoolExecutor(max_workers=8) as pool:
        results = list(pool.map(lambda i: {"id": i, **_one(engine, method, tpl.format(id=quote(i, safe="")))}, ids))
    return {"ok": all(r["ok"] for r in results), "results": results}


def remove(engine: Engine, kind: str, ident: str) -> dict:
    path = {"rmi": "/images/{}?force=0", "rmvol": "/volumes/{}", "rmnet": "/networks/{}"}[kind]
    r = _one(engine, "DELETE", path.format(quote(ident, safe="")))
    return {"ok": r["ok"], "message": r["message"]}


def prune(engine: Engine, what: str) -> dict:
    filters = json.dumps({"dangling": ["false"]}) if what == "images-all" else None
    routes = {
        "containers": "/containers/prune",
        "images": "/images/prune",
        "images-all": f"/images/prune?filters={quote(filters or '')}",
        "volumes": "/volumes/prune",
        "builder": "/build/prune?all=0",
    }
    if what not in routes:
        raise EngineError("usage", f"Unknown prune target {what!r}")
    res = engine.call("POST", routes[what], timeout=120) or {}
    freed = res.get("SpaceReclaimed", 0) or 0
    removed = len(res.get("ContainersDeleted") or res.get("ImagesDeleted") or res.get("VolumesDeleted") or [])
    return {"ok": True, "freed": freed, "removed": removed}


def logs(engine: Engine, cid: str, tail: int) -> dict:
    meta = engine.call("GET", f"/containers/{quote(cid, safe='')}/json")
    tty = bool((meta.get("Config") or {}).get("Tty"))
    tail = max(1, min(int(tail), 2000))
    status, raw = engine.request(
        "GET", f"/containers/{quote(cid, safe='')}/logs?stdout=1&stderr=1&tail={tail}", timeout=20
    )
    if status != 200:
        raise EngineError("api", _api_message(raw) or f"HTTP {status}")
    if not tty:
        out, i = [], 0
        while i + 8 <= len(raw):
            size = int.from_bytes(raw[i + 4 : i + 8], "big")
            out.append(raw[i + 8 : i + 8 + size])
            i += 8 + size
        raw = b"".join(out)
    truncated = len(raw) > MAX_LOG_BYTES
    text = ANSI.sub("", raw[-MAX_LOG_BYTES:].decode("utf-8", "replace")).replace("\r\n", "\n")
    return {"ok": True, "text": text, "truncated": truncated}


def inspect(engine: Engine, cid: str) -> dict:
    d = engine.call("GET", f"/containers/{quote(cid, safe='')}/json") or {}
    cfg, host, state = d.get("Config") or {}, d.get("HostConfig") or {}, d.get("State") or {}
    nets = (d.get("NetworkSettings") or {}).get("Networks") or {}
    return {
        "ok": True,
        "id": d.get("Id", ""),
        "restartPolicy": (host.get("RestartPolicy") or {}).get("Name", "") or "no",
        "restarts": d.get("RestartCount", 0),
        "startedAt": state.get("StartedAt", ""),
        "exitCode": state.get("ExitCode", 0),
        "oomKilled": bool(state.get("OOMKilled")),
        "envCount": len(cfg.get("Env") or []),
        "workdir": cfg.get("WorkingDir", ""),
        "networks": [{"name": k, "ip": v.get("IPAddress", "")} for k, v in nets.items()],
        "mounts": [
            {
                "type": m.get("Type", ""),
                "src": m.get("Name") or m.get("Source", ""),
                "dst": m.get("Destination", ""),
                "rw": m.get("RW", True),
            }
            for m in d.get("Mounts") or []
        ],
        "tty": bool(cfg.get("Tty")),
    }


# -------------------------------------------------------------------------- main


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(add_help=False)
    ap.add_argument("--socket", default="auto")
    ap.add_argument("cmd")
    ap.add_argument("args", nargs="*")
    ns = ap.parse_args(argv)
    try:
        engine = connect(ns.socket)
        a = ns.args
        if ns.cmd == "ping":
            out = {"ok": True, "socket": engine.path}
        elif ns.cmd == "snapshot":
            out = snapshot(engine)
        elif ns.cmd == "df":
            out = disk_usage(engine)
        elif ns.cmd == "act":
            out = act(engine, a[0], a[1:])
        elif ns.cmd in ("rmi", "rmvol", "rmnet"):
            out = remove(engine, ns.cmd, a[0])
        elif ns.cmd == "prune":
            out = prune(engine, a[0])
        elif ns.cmd == "logs":
            out = logs(engine, a[0], int(a[1]) if len(a) > 1 else 200)
        elif ns.cmd == "inspect":
            out = inspect(engine, a[0])
        else:
            raise EngineError("usage", f"Unknown command {ns.cmd!r}")
    except EngineError as e:
        out = {"ok": False, "error": e.kind, "message": e.message, "hint": e.hint}
    except Exception as e:  # noqa: BLE001 - the widget must always get JSON
        out = {"ok": False, "error": "internal", "message": f"{type(e).__name__}: {e}", "hint": ""}
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stdout.write(json.dumps(out, separators=(",", ":"), ensure_ascii=False) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

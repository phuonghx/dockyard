#!/usr/bin/env python3
"""A stateful fake Docker Engine on a unix socket, for tests and screenshots.

    fake_engine.py /tmp/fake-docker.sock

Start/stop/restart/pause/kill/rm really change the state, so the widget can be
driven end to end without touching a real daemon.
"""
import hashlib, json, os, random, re, socketserver, sys, threading, time
from http.server import BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

NOW = int(time.time())
H = 3600
GB = 1024**3
MB = 1024**2


def img_id(ref):
    return "sha256:" + hashlib.sha256((ref or "untagged").encode()).hexdigest()


def C(name, image, state, status, project="", service="", ports=(), cpu=0.0, mem=0, nets=("bridge",), mounts=(), age=2 * H):
    cid = (re.sub(r"[^a-z0-9]", "", name.encode().hex()) * 8)[:64]
    return {
        "Id": cid, "Names": ["/" + name], "Image": image, "ImageID": img_id(image),
        "Command": "docker-entrypoint.sh " + (service or name), "Created": NOW - age, "State": state, "Status": status,
        "Ports": [{"IP": "0.0.0.0", "PrivatePort": pr, "PublicPort": pu, "Type": "tcp"} for pu, pr in ports],
        "Labels": ({"com.docker.compose.project": project, "com.docker.compose.service": service} if project else {}),
        "Mounts": [{"Type": "volume", "Name": v, "Destination": d, "RW": True} for v, d in mounts],
        "NetworkSettings": {"Networks": {n: {"IPAddress": "172.18.0.%d" % (len(name) % 200 + 2)} for n in nets}},
        "_cpu": cpu, "_mem": mem,
    }


CONTAINERS = [
    C("shop-web", "ghcr.io/acme/shop-web:2.14.0", "running", "Up 3 days", "shop", "web", [(8080, 3000)], 3.4, 212 * MB, ("shop_default",), age=72 * H),
    C("shop-api", "ghcr.io/acme/shop-api:2.14.0", "running", "Up 3 days (healthy)", "shop", "api", [(8000, 8000)], 12.8, 486 * MB, ("shop_default",), age=72 * H),
    C("shop-worker", "ghcr.io/acme/shop-api:2.14.0", "running", "Up 3 days", "shop", "worker", [], 7.1, 301 * MB, ("shop_default",), age=72 * H),
    C("shop-db", "postgres:17-alpine", "running", "Up 3 days (unhealthy)", "shop", "db", [(5432, 5432)], 21.5, 1180 * MB, ("shop_default",), [("shop_pgdata", "/var/lib/postgresql/data")], 72 * H),
    C("shop-redis", "redis:7.4-alpine", "running", "Up 3 days (healthy)", "shop", "redis", [(6379, 6379)], 0.6, 18 * MB, ("shop_default",), [("shop_redis", "/data")], 72 * H),
    C("shop-mailer", "ghcr.io/acme/mailer:0.9.2", "restarting", "Restarting (1) 12 seconds ago", "shop", "mailer", [], 0.0, 0, ("shop_default",), age=72 * H),
    C("grafana", "grafana/grafana:11.3.0", "running", "Up 9 hours (healthy)", "monitoring", "grafana", [(3001, 3000)], 2.2, 164 * MB, ("monitoring",), [("grafana_data", "/var/lib/grafana")], 9 * H),
    C("prometheus", "prom/prometheus:v3.0.1", "running", "Up 9 hours", "monitoring", "prometheus", [(9090, 9090)], 5.9, 352 * MB, ("monitoring",), [("prom_data", "/prometheus")], 9 * H),
    C("loki", "grafana/loki:3.3.0", "paused", "Up 9 hours (Paused)", "monitoring", "loki", [(3100, 3100)], 0.0, 96 * MB, ("monitoring",), age=9 * H),
    C("ollama", "ollama/ollama:0.5.4", "running", "Up 26 hours", "", "", [(11434, 11434)], 0.9, 4200 * MB, ("bridge",), [("ollama_models", "/root/.ollama")], 26 * H),
    C("mapserver", "camptocamp/mapserver:8.0", "running", "Up 2 hours (health: starting)", "", "", [(8085, 80)], 4.3, 17 * MB, age=2 * H),
    C("migrate-once", "ghcr.io/acme/shop-api:2.14.0", "exited", "Exited (0) 3 days ago", "shop", "migrate", [], 0, 0, ("shop_default",), age=72 * H),
    C("nightly-export", "alpine:3.20", "exited", "Exited (137) 5 hours ago", "", "", [], 0, 0, age=24 * H),
]
IMAGES = [
    ("ghcr.io/acme/shop-web:2.14.0", 312 * MB), ("ghcr.io/acme/shop-api:2.14.0", 596 * MB), ("postgres:17-alpine", 278 * MB),
    ("redis:7.4-alpine", 41 * MB), ("grafana/grafana:11.3.0", 468 * MB), ("prom/prometheus:v3.0.1", 291 * MB), ("grafana/loki:3.3.0", 142 * MB),
    ("ollama/ollama:0.5.4", int(3.4 * GB)), ("camptocamp/mapserver:8.0", 705 * MB), ("alpine:3.20", 8 * MB), ("ghcr.io/acme/mailer:0.9.2", 120 * MB),
    ("node:22-slim", 245 * MB), (None, 1100 * MB),
]
VOLUMES = [("shop_pgdata", 2 * GB), ("shop_redis", 12 * MB), ("grafana_data", 88 * MB), ("prom_data", int(1.6 * GB)), ("ollama_models", int(3.1 * GB)), ("a" * 64, 4 * MB), ("old_experiment", 512 * MB)]
NETWORKS = [("bridge", "bridge"), ("host", "host"), ("none", "null"), ("shop_default", "bridge"), ("monitoring", "bridge")]
LOG = """2026-11-26T09:58:01Z INFO  server listening on :8000
2026-11-26T09:58:03Z INFO  connected to postgres://shop-db:5432/shop
2026-11-26T09:58:44Z INFO  GET /api/v1/products 200 12ms
2026-11-26T09:59:10Z WARN  slow query (412ms): SELECT * FROM orders WHERE status = $1
2026-11-26T09:59:32Z INFO  GET /api/v1/orders 200 431ms
2026-11-26T10:00:02Z ERROR payment provider timeout after 5000ms (attempt 2/3)
2026-11-26T10:00:07Z INFO  retrying payment capture order=84213
2026-11-26T10:00:09Z INFO  POST /api/v1/checkout 201 118ms
2026-11-26T10:01:15Z WARN  pool nearly exhausted: 18/20 connections
2026-11-26T10:01:16Z ERROR could not serialize access due to concurrent update
    at orders.update (/app/src/orders.ts:204:17)
    at async checkout (/app/src/routes/checkout.ts:88:5)
2026-11-26T10:02:00Z INFO  healthcheck ok
"""
lock = threading.Lock()
by_id = {c["Id"]: c for c in CONTAINERS}


def find(ref):
    return by_id.get(ref) or next((c for c in CONTAINERS if c["Id"].startswith(ref) or c["Names"][0] == "/" + ref), None)


class H_(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *a): pass

    def send(self, code, body=b"", ctype="application/json"):
        if not isinstance(body, bytes):
            body = json.dumps(body).encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self): self.route("GET")
    def do_POST(self): self.route("POST")
    def do_DELETE(self): self.route("DELETE")

    def route(self, m):
        u = urlparse(self.path); p = u.path; q = parse_qs(u.query)
        p = re.sub(r"^/v[0-9.]+", "", p)
        if p == "/_ping": return self.send(200, b"OK", "text/plain")
        if p == "/version": return self.send(200, {"Version": "29.10.0", "ApiVersion": "1.57", "Components": [{"Name": "Engine"}]})
        if p == "/info": return self.send(200, {"NCPU": 16, "MemTotal": 32 * GB, "OperatingSystem": "Fedora Linux 45", "SecurityOptions": ["name=seccomp,profile=builtin", "name=cgroupns"]})
        with lock:
            if p == "/containers/json":
                return self.send(200, [{k: v for k, v in c.items() if not k.startswith("_")} for c in CONTAINERS])
            mm = re.match(r"^/containers/([^/]+)/(\w+)$", p) or re.match(r"^/containers/([^/]+)$", p)  # noqa
            if mm:
                c = find(mm.group(1)); verb = mm.group(2) if mm.lastindex == 2 else ""
                if not c: return self.send(404, {"message": "No such container: " + mm.group(1)})
                if m == "GET" and verb == "stats":
                    run = c["State"] == "running"
                    cpu_total, sys_total = 10**12, 10**13
                    d_sys = 10**9
                    d_cpu = int(d_sys * (c["_cpu"] * random.uniform(0.55, 1.5) / 100.0) / 16) if run else 0
                    return self.send(200, {"cpu_stats": {"cpu_usage": {"total_usage": cpu_total + d_cpu}, "system_cpu_usage": sys_total + d_sys, "online_cpus": 16},
                        "precpu_stats": {"cpu_usage": {"total_usage": cpu_total}, "system_cpu_usage": sys_total},
                        "memory_stats": {"usage": c["_mem"] + int(random.uniform(0, 9) * MB) + 8 * MB, "limit": 32 * GB, "stats": {"inactive_file": 8 * MB}},
                        "networks": {"eth0": {"rx_bytes": 83 * MB, "tx_bytes": 41 * MB}}, "pids_stats": {"current": 14}})
                if m == "GET" and verb == "logs":
                    body = b""
                    for line in LOG.splitlines():
                        b = (line + "\n").encode(); body += bytes([1, 0, 0, 0]) + len(b).to_bytes(4, "big") + b
                    return self.send(200, body, "application/vnd.docker.raw-stream")
                if m == "GET" and verb == "json":
                    return self.send(200, {"Id": c["Id"], "Config": {"Tty": False, "Env": ["A=1", "B=2", "C=3"], "WorkingDir": "/app"},
                        "HostConfig": {"RestartPolicy": {"Name": "unless-stopped"}}, "RestartCount": 0,
                        "State": {"StartedAt": "2026-11-23T08:00:00Z", "ExitCode": 0, "OOMKilled": False},
                        "NetworkSettings": c["NetworkSettings"], "Mounts": c["Mounts"]})
                if m == "POST" and verb in ("start", "stop", "restart", "pause", "unpause", "kill"):
                    st = {"start": ("running", "Up Less than a second"), "restart": ("running", "Up Less than a second"),
                          "stop": ("exited", "Exited (0) Less than a second ago"), "kill": ("exited", "Exited (137) Less than a second ago"),
                          "pause": ("paused", "Up 3 hours (Paused)"), "unpause": ("running", "Up 3 hours")}[verb]
                    c["State"], c["Status"] = st
                    time.sleep(0.4)
                    return self.send(204)
                if m == "DELETE" and not verb:
                    CONTAINERS.remove(c); return self.send(204)
            if p == "/images/json":
                used = {c["Image"] for c in CONTAINERS}
                return self.send(200, [{"Id": img_id(t), "RepoTags": [t] if t else ["<none>:<none>"], "Size": s, "Created": NOW - (i + 1) * 86400} for i, (t, s) in enumerate(IMAGES)])
            if p == "/volumes": return self.send(200, {"Volumes": [{"Name": n, "Driver": "local", "CreatedAt": "2026-10-01T00:00:00Z", "Labels": ({"com.docker.compose.project": n.split("_")[0]} if "_" in n else {})} for n, _ in VOLUMES]})
            if p == "/networks": return self.send(200, [{"Id": (n.encode().hex() * 8)[:64], "Name": n, "Driver": d, "Scope": "local", "Internal": False} for n, d in NETWORKS])
            if p == "/system/df":
                return self.send(200, {"Images": [{"Size": s, "Containers": 0 if t is None or t.startswith(("node", "alpine")) else 1} for t, s in IMAGES],
                    "Containers": [{"SizeRw": 12 * MB, "State": c["State"]} for c in CONTAINERS],
                    "Volumes": [{"Name": n, "UsageData": {"Size": s, "RefCount": 0 if n in ("old_experiment", "a" * 64) else 1}} for n, s in VOLUMES],
                    "BuildCache": [{"Size": int(1.2 * GB), "InUse": False}]})
            if m == "POST" and p.endswith("/prune"):
                return self.send(200, {"SpaceReclaimed": 1100 * MB, "ImagesDeleted": [{}]})
            if m == "DELETE":
                return self.send(204)
        self.send(404, {"message": "page not found: " + self.path})


class Srv(socketserver.ThreadingMixIn, socketserver.UnixStreamServer):
    daemon_threads = True


def serve(path):
    if os.path.exists(path): os.unlink(path)
    s = Srv(path, H_); return s


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if "--empty" in sys.argv:        # a fresh machine: nothing yet
        CONTAINERS.clear(); IMAGES.clear(); VOLUMES.clear(); NETWORKS[:] = NETWORKS[:3]
    srv = serve(args[0] if args else "/tmp/dockyard-fake.sock")
    print("fake engine on", srv.server_address, flush=True)
    srv.serve_forever()

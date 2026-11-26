<p align="center"><img src="docs/images/banner.png" alt="Dockyard: Docker and Podman widget for KDE Plasma 6. Keep every container shipshape." width="100%"></p>

<h1 align="center">Dockyard</h1>
<p align="center"><b>Keep every container shipshape.</b><br>
A fast, good-looking <b>KDE Plasma 6 widget for Docker and Podman</b>: watch and manage containers, images, volumes and logs right from your panel. Made for Fedora KDE.</p>

<p align="center">
<a href="README.md"><img alt="English" src="https://img.shields.io/badge/-English-4b5b70?style=flat-square"></a>
<a href="docs/i18n/README.vi.md"><img alt="Tiếng Việt" src="https://img.shields.io/badge/-Ti%E1%BA%BFng%20Vi%E1%BB%87t-2dd4bf?style=flat-square"></a>
<a href="docs/i18n/README.es.md"><img alt="Español" src="https://img.shields.io/badge/-Espa%C3%B1ol-2dd4bf?style=flat-square"></a>
<a href="docs/i18n/README.fr.md"><img alt="Français" src="https://img.shields.io/badge/-Fran%C3%A7ais-2dd4bf?style=flat-square"></a>
<a href="docs/i18n/README.de.md"><img alt="Deutsch" src="https://img.shields.io/badge/-Deutsch-2dd4bf?style=flat-square"></a>
<a href="docs/i18n/README.pt-BR.md"><img alt="Português (Brasil)" src="https://img.shields.io/badge/-Portugu%C3%AAs%20(Brasil)-2dd4bf?style=flat-square"></a>
<a href="docs/i18n/README.ru.md"><img alt="Русский" src="https://img.shields.io/badge/-%D0%A0%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9-2dd4bf?style=flat-square"></a>
<a href="docs/i18n/README.ja.md"><img alt="日本語" src="https://img.shields.io/badge/-%E6%97%A5%E6%9C%AC%E8%AA%9E-2dd4bf?style=flat-square"></a>
<a href="docs/i18n/README.zh-CN.md"><img alt="简体中文" src="https://img.shields.io/badge/-%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87-2dd4bf?style=flat-square"></a>
</p>

<p align="center"><a href="https://phuonghx.github.io/dockyard/"><b>Website</b></a> · <a href="#install">Install</a> · <a href="CONTRIBUTING.md">Contribute</a></p>

<p align="center">
  <a href="LICENSE"><img alt="MIT" src="https://img.shields.io/badge/license-MIT-2dd4bf"></a>
  <img alt="Plasma 6" src="https://img.shields.io/badge/KDE_Plasma-6-1d99f3">
  <img alt="Fedora" src="https://img.shields.io/badge/Fedora-KDE-51a2da">
  </p>

<p align="center"><img src="docs/images/hero.png" alt="Dockyard in dark and light themes, and the Images tab"></p>

## Why Dockyard
- **See everything at a glance.** The *manifest strip* shows your whole fleet as one row of cells, one per container, coloured by state. Click a cell to jump straight to that container.
- **Know when something is wrong.** Unhealthy, restart-looping and crashed containers are called out, and you get a desktop notification.
- **Do the common things in one click.** Start, stop, restart, pause, logs, shell, open a port in the browser.
- **Native to Fedora KDE.** Follows your Plasma colour scheme and font size, works with Docker, rootless Docker and Podman, and needs nothing beyond Python (already on Fedora).

## Install
```bash
git clone https://github.com/phuonghx/dockyard
cd dockyard
./install.sh --restart      # per-user, no root. --restart reloads plasmashell
```
Then **right-click your panel → Add Widgets → Dockyard** and drag it in. To try it first in its own window:
`plasmawindowed io.dockyard.widget`.

> **"Can't reach Docker"?** Add yourself to the group and log out and in again:
> `sudo usermod -aG docker $USER`. For Podman: `systemctl --user enable --now podman.socket`.

## A quick tour

### Your fleet at a glance
CPU and memory for everything running (with history), the manifest strip, and one-click filters:
**running**, **need attention**, **stopped**, **paused**. Containers are grouped by Compose project; a project can be started,
stopped or restarted as a whole.

<p align="center"><img src="docs/images/overview-dark.png" width="360" alt="Overview, dark theme"> &nbsp; <img src="docs/images/overview-light.png" width="360" alt="Overview, light theme"></p>

Every state has its own **shape** as well as its colour, so it reads even without colour vision:

| | State | |
|---|---|---|
| ● filled circle | Running | |
| ◌ pulsing ring | Starting (health check running) | |
| ■ rounded square | Paused | |
| ◆ filled diamond | Unhealthy or restarting | needs attention |
| ◇ hollow diamond | Exited with an error | needs attention |
| ○ hollow circle | Stopped cleanly | |

### Work on a container
Click a row to open it. You get live CPU, memory and network, image, Compose project, ports (click to open in the browser,
or copy the address for databases), networks, mounts and restart policy. From there:

| Button | What it does |
|---|---|
| **Logs** | Opens a live log page: errors in red, warnings in amber, stack traces dimmed. Choose 100 / 300 / 1000 lines, pause, copy. |
| **Shell** | Opens bash (or sh) inside the container in Konsole. |
| **Restart / Pause / Resume** | One click. |
| **Kill / Remove** | Ask twice: the button turns red and says *Remove for good?*. No modal dialogs. |

### Images, volumes and networks
Everything the engine knows about, with *In use* and *Unused* badges and an "unused only" filter. Removing something that
is still in use is refused by the engine and Dockyard tells you why.

<p align="center"><img src="docs/images/tab-images.png" width="240" alt="Images"> <img src="docs/images/tab-volumes.png" width="240" alt="Volumes"> <img src="docs/images/tab-networks.png" width="240" alt="Networks"></p>

### Free up space
The footer button opens a panel that says **what each clean-up removes and how much it should free** before you confirm:
stopped containers, dangling images, all unused images, anonymous volumes, build cache. Named volumes are never touched here.

### Friendly when things go wrong
Plain language and the exact fix, instead of a stack trace.

<p align="center"><img src="docs/images/error-not-running.png" width="240" alt="Docker is not running"> <img src="docs/images/error-permission.png" width="240" alt="No permission"> <img src="docs/images/error-no-engine.png" width="240" alt="No engine found"> <img src="docs/images/empty.png" width="240" alt="Empty state"></p>

## Speaks your language
Dockyard follows your system language, and you can pick another one at any time with the 🌐 button in the popup (or in the widget settings). The change applies instantly. The languages available are the ones in [`po/`](po/); each is shown in its own name so you can always find yours.

<p align="center"><img src="docs/images/languages.png" alt="Dockyard shown in several languages" width="860"></p>

Want another language, or a better phrase? It takes one file and no code. See [Translating](CONTRIBUTING.md#translating).

## Settings
Right-click the widget → **Configure Dockyard**.

| Setting | Default | Notes |
|---|---|---|
| Engine socket | `auto` | Finds Docker, rootless Docker and Podman. Or a path like `/run/user/1000/podman/podman.sock`. |
| Refresh while open / in background | 4 s / 20 s | Background refresh is quiet and cheap. |
| Container CLI, terminal command | `docker`, `konsole -e` | Used for **Shell**. |
| Notifications | on | Crashes, failing health checks, restart loops. |
| Language | automatic | Follow the system, or pick one. Also on the 🌐 button in the popup. |
| Theme | follow Plasma | Or always dark / always light. |
| Open on | Containers | Which tab the popup opens on. |
| Group by Compose project | on | |
| Show running count next to the panel icon | off | Takes exactly the width of the number. |

**Keyboard:** `Ctrl+F` focuses search, `Esc` clears it, closes logs, or closes the clean-up panel. Everything is reachable with Tab.

## How it works
`package/contents/scripts/dockyard.py` (Python standard library only) talks to the Engine API over the unix socket and always
prints exactly one JSON document, errors included. The QML polls it and patches its lists in place, so your scroll position
and hover survive every refresh. Nothing is sent anywhere except to the local socket.

## Develop and contribute
```bash
python3 -I -m unittest discover -s tests            # backend tests against a fake engine
python3 tools/fake_engine.py /tmp/dockyard-fake.sock &
DOCKER_HOST=unix:///tmp/dockyard-fake.sock plasmawindowed io.dockyard.widget
tools/screenshots.sh                                # regenerate the images above
```
Read [CONTRIBUTING.md](CONTRIBUTING.md). Contributors agree to the [CLA](CLA.md) and follow the
[Code of Conduct](CODE_OF_CONDUCT.md). Security issues: [SECURITY.md](SECURITY.md). Changes: [CHANGELOG.md](CHANGELOG.md).

## Author
**Xuan-Phuong Hoang**

- GitHub: [@phuonghx](https://github.com/phuonghx)
- Email: phuonghx.me@gmail.com
- Facebook: [@phuonghx.me](https://facebook.com/phuonghx.me)
- WhatsApp: @phuonghx.me
- X: [@phuonghx_](https://x.com/phuonghx_)

Issues and ideas: https://github.com/phuonghx/dockyard/issues · [MIT License](LICENSE). Geist fonts © Vercel, SIL OFL 1.1.

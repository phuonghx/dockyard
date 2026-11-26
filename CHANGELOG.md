# Changelog
All notable changes to this project are documented here. Format: [Keep a Changelog](https://keepachangelog.com),
versions follow [Semantic Versioning](https://semver.org).

## [Unreleased]

## [1.0.0] - 2026-11-26
### Added
- First release of Dockyard for Plasma 6 on Fedora.
- Manifest strip: the whole fleet as one row of cells coloured by state.
- Fleet CPU and memory with history, plus per-container CPU, memory and network.
- Containers grouped by Compose project, with project-wide start, stop and restart.
- Per container: start, stop, restart, pause, kill, remove (two-step), coloured live logs, shell, clickable ports.
- Images, volumes and networks with an "unused only" filter and safe removal.
- "Free up space" panel that explains and sizes every clean-up.
- Desktop notifications for crashes, failing health checks and restart loops.
- Docker, rootless Docker and Podman detection; clear "not running" and "no permission" screens.
- Dark and light themes, bundled Geist fonts, keyboard focus, optional running count on the panel icon.
- Translations: Tiếng Việt, Español, Français, Deutsch, Português (Brasil), Русский, 日本語, 简体中文, via gettext (`po/`, `tools/i18n.sh`).
- Website on GitHub Pages (English and Vietnamese) with Open Graph, Twitter card, JSON-LD, sitemap and hreflang; README banner.
- "Open on" setting to choose which tab the popup starts on.
- Illustrated README (English and Vietnamese), contributor docs, CLA, issue and PR templates, CI.
- `tools/screenshots.sh` regenerates the README images from a fake engine.

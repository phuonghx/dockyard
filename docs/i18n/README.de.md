<p align="center"><img src="../images/banner.png" alt="Dockyard" width="100%"></p>

<p align="center">
<a href="../../README.md"><img alt="English" src="https://img.shields.io/badge/-English-2dd4bf?style=flat-square"></a>
<a href="README.vi.md"><img alt="Tiếng Việt" src="https://img.shields.io/badge/-Ti%E1%BA%BFng%20Vi%E1%BB%87t-2dd4bf?style=flat-square"></a>
<a href="README.es.md"><img alt="Español" src="https://img.shields.io/badge/-Espa%C3%B1ol-2dd4bf?style=flat-square"></a>
<a href="README.fr.md"><img alt="Français" src="https://img.shields.io/badge/-Fran%C3%A7ais-2dd4bf?style=flat-square"></a>
<a href="README.de.md"><img alt="Deutsch" src="https://img.shields.io/badge/-Deutsch-4b5b70?style=flat-square"></a>
<a href="README.pt-BR.md"><img alt="Português (Brasil)" src="https://img.shields.io/badge/-Portugu%C3%AAs%20(Brasil)-2dd4bf?style=flat-square"></a>
<a href="README.ru.md"><img alt="Русский" src="https://img.shields.io/badge/-%D0%A0%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9-2dd4bf?style=flat-square"></a>
<a href="README.ja.md"><img alt="日本語" src="https://img.shields.io/badge/-%E6%97%A5%E6%9C%AC%E8%AA%9E-2dd4bf?style=flat-square"></a>
<a href="README.zh-CN.md"><img alt="简体中文" src="https://img.shields.io/badge/-%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87-2dd4bf?style=flat-square"></a>
</p>

<h1 align="center">Dockyard</h1>
<p align="center"><b>Jeder Container in bester Ordnung.</b><br>Ein schnelles, schönes <b>KDE-Plasma-6-Widget für Docker und Podman</b>: Container, Images, Volumes und Protokolle direkt im Panel beobachten und verwalten. Gemacht für Fedora KDE.</p>

<p align="center"><a href="https://phuonghx.github.io/dockyard/de/"><b>Webseite</b></a> · <a href="#installation">Installation</a> · <a href="../../CONTRIBUTING.md">Mitmachen</a></p>

<p align="center"><img src="../images/hero.png" alt="Dockyard" width="900"></p>

## Warum Dockyard
- **Alles auf einen Blick:** der *Manifest-Streifen* zeichnet deine ganze Flotte als Reihe von Zellen, eine pro Container, nach Zustand eingefärbt. Ein Klick auf eine Zelle springt zu diesem Container.
- **Merken, wenn etwas kaputtgeht:** nicht gesunde, in Neustartschleife steckende oder abgestürzte Container fallen auf, dazu gibt es eine Desktop-Benachrichtigung.
- **Das Übliche mit einem Klick:** starten, stoppen, neu starten, pausieren, Protokolle lesen, Shell öffnen, Port im Browser öffnen.
- **Nativ unter Fedora KDE:** folgt Farbschema und Schriftgröße von Plasma; funktioniert mit Docker, rootless Docker und Podman; nur Python wird benötigt.

## Installation
```bash
git clone https://github.com/phuonghx/dockyard
cd dockyard
./install.sh --restart
```
Danach **Rechtsklick auf das Panel → Miniprogramme hinzufügen → Dockyard**. Zum Ausprobieren: `plasmawindowed io.dockyard.widget`.

> **Docker nicht erreichbar?** Füge dich der Gruppe hinzu und melde dich neu an: `sudo usermod -aG docker $USER`. Für Podman: `systemctl --user enable --now podman.socket`.

## Kurzer Rundgang
1. **Überblick:** CPU und Speicher aller laufenden Container mit Verlauf, der Manifest-Streifen und Filter *laufen / brauchen Aufmerksamkeit / gestoppt / pausiert*. Container sind nach Compose-Projekt gruppiert.
2. **Ein Container:** Zeile anklicken, um CPU, Speicher, Netzwerk, Ports und Einbindungen zu sehen, dann **Protokolle**, **Shell**, **Neu starten**, **Pausieren**, **Beenden erzwingen** oder **Entfernen**. Destruktives fragt zweimal nach.
3. **Images, Volumes, Netzwerke:** mit Badges *In Benutzung* / *Ungenutzt* und Filter „nur Ungenutzte“.
4. **Speicherplatz freigeben:** zeigt vor der Bestätigung, was jede Bereinigung entfernt und wie viel sie freigibt. Benannte Volumes bleiben unberührt.
5. **Wenn etwas schiefgeht:** klare Meldungen mit der genauen Lösung statt eines Fehlerprotokolls.

<p align="center"><img src="../images/overview-dark.png" width="300" alt="Dockyard"> <img src="../images/overview-light.png" width="300" alt="Dockyard"></p>

## Sprache
Wähle die Sprache über die Schaltfläche 🌐 im Popup oder lass **Automatisch** der Systemsprache folgen. Auch unter *Dockyard konfigurieren*. Eine weitere Sprache hinzufügen? Siehe *Translating* in [CONTRIBUTING](../../CONTRIBUTING.md#translating): eine Datei, kein Programmieren nötig.

## Mitmachen
Lies [CONTRIBUTING.md](../../CONTRIBUTING.md). Mitwirkende stimmen dem [CLA](../../CLA.md) zu und beachten den [Verhaltenskodex](../../CODE_OF_CONDUCT.md). Lizenz: [MIT](../../LICENSE).

## Autor
**Xuan-Phuong Hoang** · [GitHub @phuonghx](https://github.com/phuonghx) · phuonghx.me@gmail.com · [Facebook](https://facebook.com/phuonghx.me) · [X @phuonghx_](https://x.com/phuonghx_) · WhatsApp @phuonghx.me

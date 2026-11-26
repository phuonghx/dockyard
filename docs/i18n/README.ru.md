<p align="center"><img src="../images/banner.png" alt="Dockyard" width="100%"></p>

<p align="center">
<a href="../../README.md"><img alt="English" src="https://img.shields.io/badge/-English-2dd4bf?style=flat-square"></a>
<a href="README.vi.md"><img alt="Tiếng Việt" src="https://img.shields.io/badge/-Ti%E1%BA%BFng%20Vi%E1%BB%87t-2dd4bf?style=flat-square"></a>
<a href="README.es.md"><img alt="Español" src="https://img.shields.io/badge/-Espa%C3%B1ol-2dd4bf?style=flat-square"></a>
<a href="README.fr.md"><img alt="Français" src="https://img.shields.io/badge/-Fran%C3%A7ais-2dd4bf?style=flat-square"></a>
<a href="README.de.md"><img alt="Deutsch" src="https://img.shields.io/badge/-Deutsch-2dd4bf?style=flat-square"></a>
<a href="README.pt-BR.md"><img alt="Português (Brasil)" src="https://img.shields.io/badge/-Portugu%C3%AAs%20(Brasil)-2dd4bf?style=flat-square"></a>
<a href="README.ru.md"><img alt="Русский" src="https://img.shields.io/badge/-%D0%A0%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9-4b5b70?style=flat-square"></a>
<a href="README.ja.md"><img alt="日本語" src="https://img.shields.io/badge/-%E6%97%A5%E6%9C%AC%E8%AA%9E-2dd4bf?style=flat-square"></a>
<a href="README.zh-CN.md"><img alt="简体中文" src="https://img.shields.io/badge/-%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87-2dd4bf?style=flat-square"></a>
</p>

<h1 align="center">Dockyard</h1>
<p align="center"><b>Держите каждый контейнер в порядке.</b><br>Быстрый и аккуратный виджет <b>KDE Plasma 6 для Docker и Podman</b>: следите за контейнерами, образами, томами и журналами и управляйте ими прямо с панели. Создан для Fedora KDE.</p>

<p align="center"><a href="https://phuonghx.github.io/dockyard/ru/"><b>Сайт</b></a> · <a href="#установка">Установка</a> · <a href="../../CONTRIBUTING.md">Участие</a></p>

<p align="center"><img src="../images/hero.png" alt="Dockyard" width="900"></p>

## Почему Dockyard
- **Всё с одного взгляда:** *полоса манифеста* рисует весь парк контейнеров рядом ячеек, по одной на контейнер, цвет зависит от состояния. Щёлкните ячейку, чтобы перейти к контейнеру.
- **Узнавайте, когда что-то ломается:** нездоровые, перезапускающиеся в цикле и упавшие контейнеры выделяются, и приходит уведомление на рабочем столе.
- **Привычное в один щелчок:** запуск, остановка, перезапуск, пауза, журналы, оболочка, открытие порта в браузере.
- **Родной для Fedora KDE:** следует цветовой схеме и размеру шрифта Plasma; работает с Docker, rootless Docker и Podman; нужен только Python.

## Установка
```bash
git clone https://github.com/phuonghx/dockyard
cd dockyard
./install.sh --restart
```
Затем **правый щелчок по панели → Добавить виджеты → Dockyard**. Чтобы сначала попробовать: `plasmawindowed io.dockyard.widget`.

> **Нет доступа к Docker?** Добавьте себя в группу и перезайдите в систему: `sudo usermod -aG docker $USER`. Для Podman: `systemctl --user enable --now podman.socket`.

## Быстрый обзор
1. **Обзор:** ЦП и память всего запущенного с историей, полоса манифеста и фильтры *работают / требуют внимания / остановлены / на паузе*. Контейнеры сгруппированы по проектам Compose.
2. **Один контейнер:** щёлкните строку, чтобы увидеть ЦП, память, сеть, порты и тома, затем **Журнал**, **Оболочка**, **Перезапустить**, **Приостановить**, **Принудительно остановить** или **Удалить**. Опасное требует двойного подтверждения.
3. **Образы, тома и сети:** с метками *Используется* / *Не используется* и фильтром «только неиспользуемые».
4. **Освободить место:** перед подтверждением показывает, что удалит каждая очистка и сколько места освободит. Именованные тома не трогаются.
5. **Когда что-то не так:** понятные сообщения с точным решением вместо трассировки ошибки.

<p align="center"><img src="../images/overview-dark.png" width="300" alt="Dockyard"> <img src="../images/overview-light.png" width="300" alt="Dockyard"></p>

## Язык
Выберите язык кнопкой 🌐 во всплывающем окне или оставьте **Автоматически**, чтобы следовать языку системы. Также в *Настроить Dockyard*. Хотите добавить язык? См. *Translating* в [CONTRIBUTING](../../CONTRIBUTING.md#translating): достаточно одного файла, программировать не нужно.

## Участие
Прочитайте [CONTRIBUTING.md](../../CONTRIBUTING.md). Участники соглашаются с [CLA](../../CLA.md) и соблюдают [Кодекс поведения](../../CODE_OF_CONDUCT.md). Лицензия [MIT](../../LICENSE).

## Автор
**Xuan-Phuong Hoang** · [GitHub @phuonghx](https://github.com/phuonghx) · phuonghx.me@gmail.com · [Facebook](https://facebook.com/phuonghx.me) · [X @phuonghx_](https://x.com/phuonghx_) · WhatsApp @phuonghx.me

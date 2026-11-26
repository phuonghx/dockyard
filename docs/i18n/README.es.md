<p align="center"><img src="../images/banner.png" alt="Dockyard" width="100%"></p>

<p align="center">
<a href="../../README.md"><img alt="English" src="https://img.shields.io/badge/-English-2dd4bf?style=flat-square"></a>
<a href="README.vi.md"><img alt="Tiếng Việt" src="https://img.shields.io/badge/-Ti%E1%BA%BFng%20Vi%E1%BB%87t-2dd4bf?style=flat-square"></a>
<a href="README.es.md"><img alt="Español" src="https://img.shields.io/badge/-Espa%C3%B1ol-4b5b70?style=flat-square"></a>
<a href="README.fr.md"><img alt="Français" src="https://img.shields.io/badge/-Fran%C3%A7ais-2dd4bf?style=flat-square"></a>
<a href="README.de.md"><img alt="Deutsch" src="https://img.shields.io/badge/-Deutsch-2dd4bf?style=flat-square"></a>
<a href="README.pt-BR.md"><img alt="Português (Brasil)" src="https://img.shields.io/badge/-Portugu%C3%AAs%20(Brasil)-2dd4bf?style=flat-square"></a>
<a href="README.ru.md"><img alt="Русский" src="https://img.shields.io/badge/-%D0%A0%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9-2dd4bf?style=flat-square"></a>
<a href="README.ja.md"><img alt="日本語" src="https://img.shields.io/badge/-%E6%97%A5%E6%9C%AC%E8%AA%9E-2dd4bf?style=flat-square"></a>
<a href="README.zh-CN.md"><img alt="简体中文" src="https://img.shields.io/badge/-%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87-2dd4bf?style=flat-square"></a>
</p>

<h1 align="center">Dockyard</h1>
<p align="center"><b>Mantén cada contenedor a punto.</b><br>Un widget de <b>KDE Plasma 6 para Docker y Podman</b>, rápido y cuidado: vigila y gestiona contenedores, imágenes, volúmenes y registros desde el panel. Hecho para Fedora KDE.</p>

<p align="center"><a href="https://phuonghx.github.io/dockyard/"><b>Sitio web</b></a> · <a href="#instalación">Instalación</a> · <a href="../../CONTRIBUTING.md">Contribuir</a></p>

<p align="center"><img src="../images/hero.png" alt="Dockyard" width="900"></p>

## Por qué Dockyard
- **Todo de un vistazo:** la *tira de manifiesto* dibuja toda tu flota como una fila de celdas, una por contenedor, coloreadas según su estado. Haz clic en una celda para ir a ese contenedor.
- **Entérate cuando algo falla:** los contenedores no saludables, en bucle de reinicios o caídos se destacan y recibes una notificación de escritorio.
- **Lo habitual, en un clic:** iniciar, detener, reiniciar, pausar, ver registros, abrir un shell, abrir un puerto en el navegador.
- **Nativo en Fedora KDE:** sigue el esquema de colores y el tamaño de letra de Plasma; funciona con Docker, Docker rootless y Podman; solo necesita Python.

## Instalación
```bash
git clone https://github.com/phuonghx/dockyard
cd dockyard
./install.sh --restart
```
Después, **clic derecho en el panel → Añadir widgets → Dockyard**. Para probarlo antes: `plasmawindowed io.dockyard.widget`.

> **¿No llega a Docker?** Añádete al grupo y vuelve a iniciar sesión: `sudo usermod -aG docker $USER`. Para Podman: `systemctl --user enable --now podman.socket`.

## Recorrido rápido
1. **Visión general:** CPU y memoria de todo lo que corre, con historial, la tira de manifiesto y filtros *en ejecución / requieren atención / detenidos / en pausa*. Los contenedores se agrupan por proyecto de Compose.
2. **Un contenedor:** haz clic en su fila para ver CPU, memoria, red, puertos y montajes, y usa **Registros**, **Shell**, **Reiniciar**, **Pausar**, **Forzar parada** o **Eliminar**. Lo destructivo pide confirmación en dos pasos.
3. **Imágenes, volúmenes y redes:** con etiquetas *En uso* / *Sin usar* y filtro de «solo sin usar».
4. **Liberar espacio:** explica qué elimina cada limpieza y cuánto libera antes de confirmar. Los volúmenes con nombre no se tocan.
5. **Cuando algo falla:** mensajes claros con la solución exacta, no un volcado de errores.

<p align="center"><img src="../images/overview-dark.png" width="300" alt="Dockyard"> <img src="../images/overview-light.png" width="300" alt="Dockyard"></p>

## Idioma
Elige el idioma con el botón 🌐 del popup, o deja **Automático** para seguir el del sistema. También está en *Configurar Dockyard*. ¿Quieres añadir otro? Mira *Translating* en [CONTRIBUTING](../../CONTRIBUTING.md#translating): basta con un archivo, sin programar.

## Contribuir
Lee [CONTRIBUTING.md](../../CONTRIBUTING.md). Quien contribuye acepta el [CLA](../../CLA.md) y sigue el [Código de conducta](../../CODE_OF_CONDUCT.md). Licencia [MIT](../../LICENSE).

## Autor
**Xuan-Phuong Hoang** · [GitHub @phuonghx](https://github.com/phuonghx) · phuonghx.me@gmail.com · [Facebook](https://facebook.com/phuonghx.me) · [X @phuonghx_](https://x.com/phuonghx_) · WhatsApp @phuonghx.me

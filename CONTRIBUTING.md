# Contributing to Dockyard

Thanks for helping keep every container shipshape. Bug reports, ideas, translations, design feedback and
code are all welcome.

## Before you start
1. Read the [Code of Conduct](CODE_OF_CONDUCT.md).
2. Read the [Contributor License Agreement](CLA.md). **Every contributor must agree to it** before a pull
   request can be merged (tick the box in the PR template, or comment on your first PR).
3. For anything bigger than a small fix, open an issue first so we can agree on the approach.

## Set up
You need Fedora KDE (or any Plasma 6 system), `python3`, `kpackagetool6` and Docker or Podman.

```bash
git clone https://github.com/phuonghx/dockyard
cd dockyard
./install.sh                        # installs the widget for your user
python3 -I -m unittest discover -s tests
```

### Try it without touching your real containers
```bash
python3 tools/fake_engine.py /tmp/dockyard-fake.sock &
DOCKER_HOST=unix:///tmp/dockyard-fake.sock plasmawindowed io.dockyard.widget
```
The fake engine is stateful: start, stop, restart, pause and remove really change it.

QML errors show up in the terminal that runs `plasmawindowed`. After editing QML, run `./install.sh`
again and restart the window. To reload inside your panel use `./install.sh --restart`.

## Layout
- `package/contents/scripts/dockyard.py`: the engine helper (Python stdlib only; always prints one JSON document).
- `package/contents/ui/`: the widget. `Backend.qml` holds state, `Theme.qml` holds design tokens, `Full.qml` is the popup.
- `tools/fake_engine.py`: fake Docker Engine for tests and screenshots.
- `tests/`: backend tests.

## Design rules
Dockyard is an Operate-mode tool: it should disappear into the task.
- Use `Theme` tokens and `Txt`, `IconButton`, `Chip`. No hard-coded colours or font sizes.
- State is never colour alone: each state also has its own shape (see `StatusDot.qml`).
- Every interactive part has hover, focus, disabled and busy states, and works with the keyboard.
- Destructive actions ask twice (the button changes to a confirm state), never a modal.
- Lists are patched in place (`logic.js: syncModel`). Never reassign a Repeater/ListView model with new
  objects on every refresh; it flashes and resets scrolling.
- Respect the Plasma colour scheme and the user's font size.

## Translating
Translations use standard gettext files in `po/`. You do not need to know QML.

```bash
tools/i18n.sh new it          # start Italian: creates po/it.po from the template
# translate po/it.po with any PO editor (Lokalize, Poedit) or a text editor
tools/i18n.sh compile         # builds the .mo files into the package
tools/i18n.sh check           # no fuzzy, empty or broken entries
./install.sh && LANGUAGE=it plasmawindowed io.dockyard.widget
```
- Keep placeholders such as `%1` and `%2` exactly as they are. They are filled in at run time.
- Read the context in the comments of the `.pot` file. For example *Paused* appears as a container state and as a log state.
- Keep short durations compact (`3d`, `9h`); use your language's usual abbreviations.
- If you change or add UI text in the code, always wrap it in `L10n.t("...")` (or `L10n.tc` for a context, `L10n.tn` for plurals), then run `tools/i18n.sh all`. Settings pages use `i18n("...")`.
- The widget lets users pick a language at run time, so it reads `package/contents/ui/translations.js`, generated from `po/` by `tools/po2js.py` (done by `tools/i18n.sh compile`). Commit it with your `.po` change.
- Singletons and `logic.js` do not write words: they emit codes and the UI (`Tr.qml`, `Full.qml`) turns them into text.
- A new language shows up in the picker by adding its code to `codes`/`names` in `L10n.qml` and to the list in `ConfigAppearance.qml`.
- READMEs in other languages live in `docs/i18n/README.<lang>.md`; the language buttons at the top of each README link them.

## Code style
- Python: stdlib only, type hints where they help, no traceback ever reaches the widget (errors become JSON).
- QML: 4 spaces, one component per file, register new components in `qmldir`.
- Keep strings plain and specific: say what happened and what to do next.

## Commits and pull requests
- Small, focused commits. Conventional style is welcome: `fix: ...`, `feat: ...`, `docs: ...`.
- Run the tests, and run the widget against the fake engine, before opening a PR.
- Describe what you changed and why. Add a screenshot for visual changes (light and dark if relevant).
- Update `CHANGELOG.md` under *Unreleased*.

## Reporting bugs
Use the issue template. The most useful details: Fedora and Plasma versions, Docker or Podman version,
the output of `python3 package/contents/scripts/dockyard.py snapshot | head -c 600`, and what you expected.

## Security
Please do not open a public issue for a vulnerability. See [SECURITY.md](SECURITY.md).

## License
By contributing you agree to the [CLA](CLA.md), and your work is distributed under the [MIT License](LICENSE).

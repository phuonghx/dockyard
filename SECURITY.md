# Security policy

## Supported versions
Only the latest release receives security fixes.

## Reporting a vulnerability
Please **do not** open a public issue. Email **phuonghx.me@gmail.com** with:
- what you found and why it matters,
- steps to reproduce,
- your Fedora, Plasma and Docker/Podman versions.

You will get a reply within 7 days. We will agree on a fix and a disclosure date with you, and credit you if you wish.

## Things worth knowing
Dockyard talks to the Docker or Podman socket, and **access to the Docker socket is equivalent to root** on the
machine. Dockyard:
- never sends data anywhere except to the local engine socket,
- runs only the bundled helper (`dockyard.py`) and, on request, your configured terminal and CLI,
- quotes every argument it passes to a shell,
- stores no credentials.

If you set a custom terminal or CLI command in the settings, it runs with your privileges. Only use commands you trust.

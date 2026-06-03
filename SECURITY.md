# Security Policy

## Reporting a vulnerability

Please open a private security advisory on GitHub if available, or contact the maintainer directly.

Do not publicly disclose a vulnerability until a fix or mitigation is available.

## Scope

Security issues in this project include:

- unsafe shell behavior
- privilege escalation bugs caused by the helper
- incorrect file permissions
- downloading from non-official sources
- desktop integration that runs unexpected commands

Security issues in Google Antigravity itself should be reported to Google through their official channels.

## Design choices

- The installer downloads official Google tarballs at install/update time.
- The project does not host Google binaries.
- The installer writes only helper-managed system files and leaves user home settings untouched during uninstall.
- The Electron/Chromium sandbox is preserved by setting `chrome-sandbox` to `root:root` with mode `4755` when present.

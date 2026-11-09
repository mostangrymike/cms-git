# Security Policy

## Supported versions
`cms-git` is experimental/research software under active development. Only the latest code on the default branch is supported with fixes on a best-effort basis.

## Reporting a vulnerability
Please **do not** open a public issue for a suspected security vulnerability.

- Use **GitHub Private Vulnerability Reporting / Security Advisories** for this repository if enabled.
- If private reporting is not available, contact the maintainer privately via GitHub with a clear description, impact, and reproduction steps.

Include (where possible): affected component/file, target environment (z/VM/CMS/Hercules/bridge path), steps to reproduce, and any relevant logs **with secrets redacted** (tokens, `GHCRED` material, passwords, authorization headers).

## Scope notes
- `cms-git` interacts with remote Git services over HTTP(S) (often via a local TLS bridge) and uses locally stored credentials on CMS (e.g. `GHCRED`). Protect credential files and never commit them.
- Treat target validation claims carefully: host/CI guards are not the same as CMS target proof.

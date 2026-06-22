# Security Policy

ConsoleDock is a debug SDK. Logs may contain sensitive data, so privacy and Release-build safeguards are part of the security model.

## Supported Versions

ConsoleDock has not published a stable release yet. Security handling is best effort until the first public tag.

| Version | Security support |
| --- | --- |
| Latest public `v0.x` tag | Best-effort fixes for security-relevant debug SDK behavior. |
| `main` | Active development; use for verification, not as a supported release line. |
| Older pre-release commits | Not supported unless the issue also affects the latest public tag or `main`. |

## Reporting a Vulnerability

Use GitHub private vulnerability reporting when it is enabled for the repository.

If private vulnerability reporting is not available yet, open a minimal public issue titled `Security report coordination` and ask maintainers to establish a private channel. Do not include exploit details, proof-of-concept code, private screenshots, production logs, credentials, tokens, cookies, API keys, customer data, or other secrets in that public issue.

When reporting privately, include:

- affected ConsoleDock version or commit;
- whether the issue affects Debug, Release, or both;
- minimal reproduction steps using synthetic data;
- expected impact for testers or app developers;
- whether sensitive data, copy/share/export, Release activation, or descriptor capture is involved.

Security-relevant reports include:

- accidental Release-build activation;
- unsafe copy, share, export, or persistence behavior;
- missing or bypassed redaction for obvious secrets;
- behavior that exposes logs from other apps or processes;
- use of private APIs.

## Handling Expectations

Maintainers should acknowledge private reports before discussing details publicly. Public disclosure should wait until a fix, mitigation, or clear non-issue determination is available.

For debug-log privacy guidance, see [Privacy and redaction](docs/privacy-and-redaction.md). For Release safeguards, see [Release build safety](docs/release-build-safety.md).

## Project Boundaries

ConsoleDock does not provide remote telemetry, does not read logs from other processes, and must not be described as a full unified logging reader.

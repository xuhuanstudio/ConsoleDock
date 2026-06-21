# Security Policy

ConsoleDock is a debug SDK. Logs may contain sensitive data, so privacy and Release-build safeguards are part of the security model.

## Supported Versions

ConsoleDock has not published a stable release yet. Security handling will become versioned after public releases begin.

## Reporting a Vulnerability

Until a dedicated security contact is configured, please open a private maintainer channel if available. Do not include secrets, production logs, credentials, tokens, or customer data in public issues.

Security-relevant reports include:

- accidental Release-build activation;
- unsafe copy, share, export, or persistence behavior;
- missing or bypassed redaction for obvious secrets;
- behavior that exposes logs from other apps or processes;
- use of private APIs.

## Project Boundaries

ConsoleDock does not provide remote telemetry, does not read logs from other processes, and must not be described as a full unified logging reader.

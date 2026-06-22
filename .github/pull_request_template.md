## Summary

## Impact

- Public API:
- Objective-C compatibility:
- Release-build behavior:
- Privacy/redaction:
- Logging boundary claims:

## Testing

## Checklist

- [ ] Public API changes are intentional and documented.
- [ ] Objective-C symbols use the `CDK` prefix where applicable.
- [ ] The change does not claim complete zero-intrusion capture of Swift `Logger` or `os_log`.
- [ ] Release startup still requires both `CONSOLEDOCK_ENABLE_RELEASE` and `allowsReleaseBuilds`.
- [ ] Privacy and redaction implications were considered.
- [ ] Relevant SwiftPM, Release safety, iOS package, or sample app checks were run.

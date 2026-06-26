# Privacy And Release Safety

Keep ConsoleDock local, memory-first, and disabled in production by default.

## Local Memory First

ConsoleDock stores logs in a bounded in-memory buffer. It does not persist raw logs to disk, upload logs, or collect logs from other processes by default.

Copy and share actions are user-initiated from the UIKit console. They use already-redacted entries from the current visible in-memory snapshot.

Local Session Archive is also explicit. It stores bounded issue-report text only after a user or app saves an archive, and archives remain local until deleted.

Support Reports are generated on demand for app-owned feedback or support flows. They read currently retained, already-redacted in-memory/session data for a selected time range, do not send network requests, and do not create a continuous log file. Temporary Support Report files are created only when requested and ConsoleDock prunes its own temporary report directory to avoid unbounded accumulation.

## Redaction Runs Before Storage

ConsoleDock redacts obvious authorization header values, cookie headers, token, ID token, auth token, session token, CSRF token, access token, refresh token, API key, client secret, key, password, passwd, and secret patterns before storing entries.

For oversized stdout or stderr lines split into partial fragments, a redacted partial causes later fragments from the same source to be stored as `<redacted partial continuation>` until that line ends. This protects long secret-bearing lines that are split before the full line is available.

Add an app-specific redactor for internal identifiers or domain-specific sensitive fields:

```swift
let configuration = ConsoleDock.Configuration(redactor: { message in
    message.replacingOccurrences(
        of: #"customer_id=\d+"#,
        with: "customer_id=<redacted>",
        options: .regularExpression
    )
})

ConsoleDock.start(configuration: configuration)
```

Redaction is a safety baseline, not a complete privacy guarantee. Avoid logging secrets in the first place.

For the full repository-level guidance, see [Privacy and redaction](../../../docs/privacy-and-redaction.md).

## Release Builds Are Disabled By Default

In Release builds, ``ConsoleDock/start(configuration:)`` returns ``ConsoleDock/StartResult/disabled`` by default.

Starting in Release requires both:

- compiling the app with `CONSOLEDOCK_ENABLE_RELEASE`;
- setting ``ConsoleDock/Configuration/allowsReleaseBuilds`` to `true`.

Keep ConsoleDock disabled in App Store production builds. Treat any accidental Release activation, unsafe export, or redaction bypass as security-relevant.

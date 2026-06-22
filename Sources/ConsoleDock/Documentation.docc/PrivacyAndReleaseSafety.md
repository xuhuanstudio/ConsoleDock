# Privacy And Release Safety

Keep ConsoleDock local, memory-first, and disabled in production by default.

## Local Memory First

ConsoleDock stores logs in a bounded in-memory buffer. It does not persist logs to disk, upload logs, or collect logs from other processes by default.

Copy and share actions are user-initiated from the UIKit console. They use already-redacted entries from the current visible in-memory snapshot.

## Redaction Runs Before Storage

ConsoleDock redacts obvious authorization header values, cookie headers, token, password, passwd, access token, refresh token, API key, client secret, key, and secret patterns before storing entries.

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

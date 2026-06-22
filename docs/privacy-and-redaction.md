# Privacy And Redaction

ConsoleDock is a debug and test SDK. Treat every captured log entry as potentially sensitive, even when the default redactor is enabled.

## Data Flow

ConsoleDock accepts entries from:

- the native ConsoleDock logging API;
- stdout capture;
- stderr capture;
- many `NSLog` writes when they pass through the app process stderr descriptor.

Every entry goes through the same core preparation path before storage:

1. ConsoleDock applies the default redactor.
2. If configured, the app-specific redactor receives the default-redacted message.
3. ConsoleDock truncates the prepared message to `maximumMessageLength`.
4. ConsoleDock stores the prepared entry in the bounded in-memory buffer.

Stored entries include `partial`, `redacted`, and `truncated` flags. The `redacted` and `truncated` flags mean ConsoleDock changed or shortened the message during preparation; they are processing metadata, not proof that the remaining text is safe to expose.

The UIKit console reads from that in-memory buffer. Selected-entry copy and share/export actions use already-redacted entries from the current visible snapshot. ConsoleDock does not persist logs to disk, upload logs, or collect logs from other apps or system processes by default.

## Default Redaction Coverage

The default redactor is a local safety baseline for obvious secrets. It is case-insensitive and currently covers common forms of:

- `Authorization: Bearer ...`
- `Cookie: ...`
- `Set-Cookie: ...`
- `password`
- `passwd`
- `token`
- `access_token` and `access-token`
- `refresh_token` and `refresh-token`
- `api_key` and `api-key`
- `client_secret` and `client-secret`
- `key`
- `secret`

The redactor handles simple key/value and quoted JSON-like values, but it is not a complete privacy guarantee. It can miss app-specific identifiers, unusual encodings, multiline payloads, custom header names, binary data, raw request bodies, or secrets that do not look like the known patterns.

## Add App-Specific Redaction

Add a custom redactor for identifiers or fields that matter in your app. The custom redactor runs after ConsoleDock's default redactor.

Swift:

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

Objective-C:

```objc
CDKConfiguration *configuration = [CDKConfiguration defaultConfiguration];
configuration.redactionBlock = ^NSString *(NSString *message) {
    NSError *error = nil;
    NSRegularExpression *expression =
        [NSRegularExpression regularExpressionWithPattern:@"customer_id=[0-9]+"
                                                  options:0
                                                    error:&error];
    if (error != nil) {
        return message;
    }

    NSRange range = NSMakeRange(0, message.length);
    return [expression stringByReplacingMatchesInString:message
                                                options:0
                                                  range:range
                                           withTemplate:@"customer_id=<redacted>"];
};

[CDKConsoleDock startWithConfiguration:configuration];
```

## Reduce Sensitive Logs At The Source

Redaction is defense in depth, not permission to log secrets. Prefer to avoid logging:

- authentication tokens, cookies, API keys, and authorization headers;
- raw request or response bodies;
- passwords, one-time codes, and session identifiers;
- payment, medical, legal, or government identifiers;
- customer names, emails, phone numbers, addresses, or account IDs unless explicitly needed for the test workflow;
- internal tenant names, private hostnames, or production infrastructure details.

When adapting an existing logger, forward already-formatted messages only after the app's normal privacy rules have run. See [Migrating existing loggers](migration-existing-loggers.md).

## Copy, Share, And Export

ConsoleDock's bundled UIKit console only copies or shares entries that are already stored in redacted form. The share sheet exports the current visible in-memory snapshot as plain text and does not create a persistent export file by itself.

Filtering changes only the visible snapshot used by the panel and share sheet. It does not mutate stored entries and does not make hidden entries safe to expose elsewhere.

## Release Builds

Keep ConsoleDock disabled in App Store production builds. Release startup is disabled by default and requires both the `CONSOLEDOCK_ENABLE_RELEASE` compile-time flag and `allowsReleaseBuilds = true`.

See [Release build safety](release-build-safety.md) for the exact gates and validation commands.

## Review Checklist

Before enabling ConsoleDock in a shared test build:

- confirm the build is not an App Store production build;
- confirm custom redaction covers app-specific identifiers;
- confirm sample logs show `<redacted>` for expected sensitive values;
- confirm testers understand that copy/share actions can expose visible logs;
- confirm no logs are persisted or uploaded by another app-specific integration without a separate privacy review.

Treat accidental Release activation, unsafe export behavior, or obvious redaction bypasses as security-relevant. See the repository [Security Policy](../SECURITY.md).

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

When stdout or stderr capture has to split an oversized line into partial fragments, ConsoleDock keeps redaction state per source. If one partial fragment is redacted, following fragments from the same source are stored as `<redacted partial continuation>` until that line ends. This favors privacy over preserving every byte of an oversized secret-bearing line.

The UIKit console reads from that in-memory buffer. Log detail copy, share/export actions, markers, and issue reports use already-redacted entries from the current in-memory store. App Context values come from the app-provided context provider and are included in issue reports as app-authored diagnostic text. Debug Action execution history and parameter summaries are local session state authored by the app or tester and can appear in issue-report reproduction timelines. ConsoleDock does not persist logs, App Context, action history, or parameter values to disk by default, upload logs or context, or collect logs from other apps or system processes by default.

## Default Redaction Coverage

The default redactor is a local safety baseline for obvious secrets. It is case-insensitive and currently covers common forms of:

- `Authorization: ...`
- `Cookie: ...`
- `Set-Cookie: ...`
- `password`
- `passwd`
- `token`
- `id_token`, `id-token`, and `idToken`
- `auth_token`, `auth-token`, and `authToken`
- `session_token`, `session-token`, and `sessionToken`
- `csrf_token`, `csrf-token`, and `csrfToken`
- `access_token`, `access-token`, and `accessToken`
- `refresh_token`, `refresh-token`, and `refreshToken`
- `api_key`, `api-key`, `apiKey`, and `x-api-key`
- `client_secret`, `client-secret`, and `clientSecret`
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

ConsoleDock's bundled UIKit console only copies or shares entries that are already stored in redacted form. The share sheet can export the current visible in-memory snapshot, all currently retained entries, or a local issue report as plain text. `Share Issue Report` creates a temporary local `.txt` item only for the user-initiated share sheet; it does not create a persistent export file by itself.

Issue reports include session metadata, diagnostics, App Context, a reproduction timeline, a marker index, and all currently retained redacted logs. The reproduction timeline can include Debug Action titles, outcomes, messages, and compact parameter summaries. They are generated through a user-initiated local share action; ConsoleDock does not upload them or create remote issues automatically.

App Context is not passed through the log redaction pipeline. Only provide values that are already appropriate for a local debug report, such as non-secret environment names, feature flag names, route labels, or explicitly redacted identifiers.

Debug Action parameter summaries are not a privacy filter. Keep parameter values limited to bounded local test inputs and avoid secrets, raw tokens, unnecessary personal data, or production customer data.

Filtering changes only the visible snapshot used by the panel and visible-log share action. It does not mutate stored entries and does not make hidden entries safe to expose elsewhere.

## Release Builds

Keep ConsoleDock disabled in App Store production builds. Release startup is disabled by default and requires both the `CONSOLEDOCK_ENABLE_RELEASE` compile-time flag and `allowsReleaseBuilds = true`.

See [Release build safety](release-build-safety.md) for the exact gates and validation commands.

## Review Checklist

Before enabling ConsoleDock in a shared test build:

- confirm the build is not an App Store production build;
- confirm custom redaction covers app-specific identifiers;
- confirm sample logs show `<redacted>` for expected sensitive values;
- confirm App Context values do not contain raw secrets or unnecessary personal data;
- confirm Debug Action parameters do not ask testers for secrets or unnecessary personal data;
- confirm testers understand that copy/share actions can expose visible logs;
- confirm no logs are persisted or uploaded by another app-specific integration without a separate privacy review.

Treat accidental Release activation, unsafe export behavior, or obvious redaction bypasses as security-relevant. See the repository [Security Policy](../SECURITY.md).

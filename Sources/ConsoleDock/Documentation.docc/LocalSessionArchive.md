# Local Session Archive

Save bounded local issue-report snapshots for later review.

## Overview

Local Session Archive is available in `v0.11.0` and later. It lets a tester or app explicitly save the current issue report so the same evidence can be reopened after an app restart.

Archives are local, app-sandbox files containing already-redacted and already-truncated issue-report text. They include report metadata such as creation time, source session id, entry count, baseline-redacted note, truncation state, and the saved report text.

ConsoleDock does not automatically persist raw logs in the background. Saving an archive is explicit through API or the bundled UIKit menu.

## Save From Swift

```swift
let archive = try ConsoleDock.saveSessionArchive(note: "Checkout smoke test")

print(archive.id)
print(archive.reportText)
```

List, delete, or clear archives:

```swift
let archives = try ConsoleDock.sessionArchives()
try ConsoleDock.deleteSessionArchive(id: archive.id)
try ConsoleDock.clearSessionArchives()
```

## Save From Objective-C

```objc
NSError *error = nil;
CDKSessionArchive *archive =
    [CDKConsoleDockUIKit saveSessionArchiveWithNote:@"Checkout smoke test"
                                             error:&error];

NSArray<CDKSessionArchive *> *archives =
    [CDKConsoleDockUIKit sessionArchivesWithError:&error];
```

Delete or clear archives through the UIKit facade:

```objc
[CDKConsoleDockUIKit deleteSessionArchiveWithIdentifier:archive.identifier
                                                  error:&error];
[CDKConsoleDockUIKit clearSessionArchivesWithError:&error];
```

## Use The Bundled UI

Open the ConsoleDock panel, tap the Logs share button, then choose:

- `Save Session Archive` to save the current issue report;
- `Saved Session Archives` to review saved archives.

The archive list can open archive detail, copy report text, share the saved report, delete one archive, or clear all archives with confirmation.

## Boundaries

Local Session Archive is not a persistent log database, crash reporter, remote upload feature, or automation platform.

Archives:

- are created only when saved explicitly;
- store bounded issue-report text, not raw pre-redaction log streams;
- apply file protection where available and are excluded from backup;
- are sorted newest first;
- may be truncated by the archive storage limit;
- persist locally until deleted by the app/user;
- do not guarantee crash-final logs.

Use ``ConsoleDock/issueReportText()`` or the live `Share Issue Report` flow when a tester needs the fullest current report before clearing logs.

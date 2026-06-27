# Support Reports

Generate bounded local reports for app-owned feedback or support flows.

## Overview

Support Reports are available in `v0.14.0` and later. They are useful when the host app already has a feedback, support, QA, or bug-report flow and wants to attach ConsoleDock context for a specific time window.

ConsoleDock does not upload Support Reports. It only builds local text from currently retained, already-redacted ConsoleDock data plus baseline-redacted report-adjacent text such as App Context and Debug Action summaries. The host app owns consent, upload, ticket creation, cleanup, and any extra privacy review.

## Build A Report

The default report covers the last 10 minutes and uses a bounded maximum text size.

```swift
let report = ConsoleDock.supportReport()
print(report.timeRangeDescription)
print(report.includedEntryCount)
print(report.isReportTruncated)
```

Use presets for common manual testing windows:

```swift
let shortReport = ConsoleDock.supportReport(options: .last5Minutes)
let defaultReport = ConsoleDock.supportReport(options: .last10Minutes)
let longerReport = ConsoleDock.supportReport(options: .last30Minutes)
let longFlowReport = ConsoleDock.supportReport(options: .last60Minutes)
```

The 60-minute preset is for longer manual flows. It does not make ConsoleDock keep more entries than the configured in-memory limits, and it does not create a continuous log file.

Use a date range when the app feedback flow has known start and end times:

```swift
let options = ConsoleDock.SupportReportOptions(
    timeRange: .range(from: startedAt, to: endedAt)
)
let report = ConsoleDock.supportReport(options: options)
```

## Create A Temporary File

Use a temporary file when the host app's feedback composer or upload stack expects a file URL:

```swift
let fileURL = try ConsoleDock.makeTemporarySupportReportFile(options: .last10Minutes)
```

Objective-C/UIKit integrations can use the facade:

```objc
NSError *error = nil;
CDKSupportReport *report =
    [CDKConsoleDockUIKit supportReportWithLastMinutes:10
                          maximumReportCharacterCount:0];
NSURL *fileURL =
    [CDKConsoleDockUIKit makeTemporarySupportReportFileWithLastMinutes:10
                                           maximumReportCharacterCount:0
                                                                 error:&error];
```

ConsoleDock creates these files on demand in its own temporary report directory and prunes older ConsoleDock temporary report files to avoid unbounded accumulation. The host app still owns upload, sharing, and cleanup for any file URL it keeps.

## Contents

A Support Report includes:

- session metadata;
- diagnostics;
- optional ConsoleDock Health lines;
- optional App Context;
- a reproduction timeline for retained markers, Debug Action executions, and retained error/fault logs in the selected range;
- retained redacted log entries in the selected range;
- a Support Report header with included/omitted counts, time range, size limit, and truncation state.

The report is generated from ConsoleDock's current bounded in-memory/session data. If older entries have already been evicted, a longer time range cannot recover them.

## Boundaries

Support Reports are not analytics, telemetry, crash reporting, background logging, remote command delivery, or automatic issue creation. ConsoleDock does not collect user statistics, send network requests, or bypass app permissions.

Treat report text as potentially sensitive even after redaction. Avoid logging secrets in the first place, keep App Context values already safe, and review the host app's feedback upload path separately from ConsoleDock.

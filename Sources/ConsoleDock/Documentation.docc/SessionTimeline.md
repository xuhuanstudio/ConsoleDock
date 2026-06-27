# Session Timeline

Review the important events in the current local debug session.

## Overview

Session Timeline is available in `v0.10.0` and later. The bundled UIKit console's `Timeline` tab aggregates three local event sources:

- marker entries created through ``ConsoleDock/mark(_:)`` or the bundled `Mark` action;
- local Debug Action executions from ``ConsoleDock/actionExecutionHistory``;
- retained error and fault log entries.

Events are sorted by timestamp so a tester can scan what happened during the current reproduction without reading the full Logs list first.

Timeline marker rows use ConsoleDock's stored marker metadata. Ordinary native logs that happen to start with `[marker]` remain normal log entries unless they were created through the marker API.

## Open Details

Marker, error, and fault timeline rows open the existing log detail screen. Debug Action rows open an action detail screen with the action id, title, outcome, timestamps, group, parameter summary, and message when available.

The Timeline view is a local UI summary. It does not persist history, upload events, discover app routes, run remote commands, or replace the full Logs list.

## Issue Reports

The issue report reproduction timeline uses the same event sources as the bundled Timeline view. Use `Share Issue Report`, `Copy Issue Report`, or ``ConsoleDock/issueReportText()`` when a tester needs to send the current session context to a developer.

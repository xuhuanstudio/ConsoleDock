#if canImport(UIKit)
    import UIKit

    enum ConsoleDockAccessibilityIdentifiers {
        static let dockButton = "consoledock.dock-button"
        static let closeButton = "consoledock.close"
        static let shareButton = "consoledock.share"
        static let shareVisibleLogs = "consoledock.share-visible-logs"
        static let shareAllLogs = "consoledock.share-all-logs"
        static let shareIssueReport = "consoledock.share-issue-report"
        static let copyIssueReport = "consoledock.copy-issue-report"
        static let saveSessionArchive = "consoledock.save-session-archive"
        static let savedSessionArchives = "consoledock.saved-session-archives"
        static let sessionArchivesTable = "consoledock.session-archives.table"
        static let sessionArchivesEmptyState = "consoledock.session-archives.empty"
        static let clearAllSessionArchivesButton = "consoledock.session-archives.clear-all"
        static let confirmClearSessionArchivesButton = "consoledock.session-archives.confirm-clear"
        static let cancelClearSessionArchivesButton = "consoledock.session-archives.cancel-clear"
        static let sessionArchiveDetailText = "consoledock.session-archive-detail.text"
        static let copySessionArchiveButton = "consoledock.session-archive-detail.copy"
        static let shareSessionArchiveButton = "consoledock.session-archive-detail.share"
        static let deleteSessionArchiveButton = "consoledock.session-archive-detail.delete"
        static let confirmDeleteSessionArchiveButton = "consoledock.session-archive-detail.confirm-delete"
        static let cancelDeleteSessionArchiveButton = "consoledock.session-archive-detail.cancel-delete"
        static let markButton = "consoledock.mark"
        static let markerTextField = "consoledock.marker-text"
        static let addMarkerButton = "consoledock.add-marker"
        static let clearButton = "consoledock.clear"
        static let jumpButton = "consoledock.jump"
        static let jumpLatestLog = "consoledock.jump-latest-log"
        static let jumpFirstError = "consoledock.jump-first-error"
        static let jumpPreviousError = "consoledock.jump-previous-error"
        static let jumpNextError = "consoledock.jump-next-error"
        static let pauseLiveButton = "consoledock.pause-live"
        static let resumeLiveButton = "consoledock.resume-live"
        static let searchBar = "consoledock.search"
        static let actionsSearchBar = "consoledock.actions-search"
        static let levelFilter = "consoledock.level-filter"
        static let status = "consoledock.status"
        static let entriesTable = "consoledock.entries-table"
        static let emptyState = "consoledock.empty-state"
        static let modeControl = "consoledock.mode-control"
        static let timelineTable = "consoledock.timeline-table"
        static let timelineEmptyState = "consoledock.timeline-empty-state"
        static let timelineRefreshButton = "consoledock.timeline-refresh"
        static let timelineActionDetailText = "consoledock.timeline-action-detail.text"
        static let timelineActionDetailCopyButton = "consoledock.timeline-action-detail.copy"
        static let actionsTable = "consoledock.actions-table"
        static let contextTable = "consoledock.context-table"
        static let contextRefreshButton = "consoledock.context-refresh"
        static let contextCopyDiagnosisButton = "consoledock.context.copy-diagnosis"
        static let entryDetailMessage = "consoledock.entry-detail.message"
        static let copyMessageButton = "consoledock.copy-message"
        static let copyEntryButton = "consoledock.copy-entry"
        static let confirmActionButton = "consoledock.confirm-action"
        static let cancelActionButton = "consoledock.cancel-action"
        static let actionParameterForm = "consoledock.action-parameters.form"
        static let actionParameterRunButton = "consoledock.action-parameters.run"
        static let actionParameterCancelButton = "consoledock.action-parameters.cancel"
        static let actionParameterError = "consoledock.action-parameters.error"
        static let actionParameterStringInput = "consoledock.action-parameters.string"
        static let actionParameterNumberInput = "consoledock.action-parameters.number"
        static let actionParameterBoolInput = "consoledock.action-parameters.bool"
        static let actionParameterChoiceInput = "consoledock.action-parameters.choice"

        static func identifier(_ base: String, parameterID: String) -> String {
            "\(base).\(parameterID)"
        }
    }

    enum ConsoleDockFonts {
        static func monospace(size: CGFloat, weight: UIFont.Weight) -> UIFont {
            if #available(iOS 13.0, *) {
                return .monospacedSystemFont(ofSize: size, weight: weight)
            }
            return UIFont(name: "Menlo", size: size) ?? .systemFont(ofSize: size, weight: weight)
        }
    }

    enum ConsoleDockUIColors {
        static let background = UIColor(white: 0.06, alpha: 1)
        static let panel = UIColor(white: 0.08, alpha: 1)
        static let separator = UIColor(white: 0.18, alpha: 1)
        static let primaryText = UIColor.white
        static let secondaryText = UIColor(white: 0.78, alpha: 1)

        static func level(_ level: ConsoleDock.LogLevel) -> UIColor {
            switch level {
            case .debug:
                return UIColor(white: 0.65, alpha: 1)
            case .info:
                return UIColor(red: 0.42, green: 0.76, blue: 1.0, alpha: 1)
            case .warning:
                return UIColor(red: 1.0, green: 0.75, blue: 0.25, alpha: 1)
            case .error, .fault:
                return UIColor(red: 1.0, green: 0.36, blue: 0.32, alpha: 1)
            }
        }
    }

    enum ConsoleDockSegmentedControlStyle {
        static func applyDarkPanelStyle(to control: UISegmentedControl) {
            let normalTextAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor(white: 0.86, alpha: 1)
            ]
            let selectedTextAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.black
            ]
            control.backgroundColor = UIColor(white: 0.1, alpha: 1)
            if #available(iOS 13.0, *) {
                control.overrideUserInterfaceStyle = .dark
                control.selectedSegmentTintColor = UIColor(white: 0.92, alpha: 1)
                control.tintColor = UIColor(white: 0.86, alpha: 1)
            } else {
                control.tintColor = UIColor(white: 0.92, alpha: 1)
            }
            control.setTitleTextAttributes(normalTextAttributes, for: .normal)
            control.setTitleTextAttributes(selectedTextAttributes, for: .selected)
        }
    }

    enum ConsoleDockTableHeaderStyle {
        static func apply(to view: UIView) {
            guard let header = view as? UITableViewHeaderFooterView else { return }
            header.tintColor = ConsoleDockUIColors.background
            header.textLabel?.font = .preferredFont(forTextStyle: .footnote)
            header.textLabel?.adjustsFontForContentSizeCategory = true
            header.textLabel?.textColor = ConsoleDockUIColors.secondaryText
        }
    }

    enum ConsoleDockPasteboard {
        static func copy(_ text: String, expiration: TimeInterval = 10 * 60) {
            let pasteboard = UIPasteboard.general
            if #available(iOS 10.0, *) {
                pasteboard.setItems(
                    [["public.utf8-plain-text": text]],
                    options: [
                        .localOnly: true,
                        .expirationDate: Date().addingTimeInterval(expiration)
                    ]
                )
            } else {
                pasteboard.string = text
            }
        }
    }

    extension ConsoleDock.LogLevel {
        var consoleDockLabel: String {
            switch self {
            case .debug:
                return "DEBUG"
            case .info:
                return "INFO"
            case .warning:
                return "WARN"
            case .error:
                return "ERROR"
            case .fault:
                return "FAULT"
            }
        }
    }

    extension ConsoleDock.LogSource {
        var consoleDockLabel: String {
            switch self {
            case .native:
                return "native"
            case .stdout:
                return "stdout"
            case .stderr:
                return "stderr"
            }
        }
    }
#endif

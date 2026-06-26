#if canImport(UIKit)
    import UIKit

    final class ConsoleDockSessionArchivesViewController: UIViewController, UITableViewDataSource,
        UITableViewDelegate
    {
        private let tableView = UITableView(frame: .zero, style: .plain)
        private let emptyStateLabel = UILabel()
        private var archives: [ConsoleDock.SessionArchive] = []
        private var clearAllButton: UIBarButtonItem?
        private var lastErrorMessage: String?

        override func viewDidLoad() {
            super.viewDidLoad()
            title = "Saved Archives"
            view.backgroundColor = ConsoleDockUIColors.background
            configureNavigationItems()
            configureTableView()
            configureEmptyStateLabel()
            reloadArchives()
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            reloadArchives()
        }

        private func configureNavigationItems() {
            let clearAllButton = UIBarButtonItem(
                title: "Clear All",
                style: .plain,
                target: self,
                action: #selector(confirmClearAll)
            )
            clearAllButton.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.clearAllSessionArchivesButton
            self.clearAllButton = clearAllButton
            navigationItem.rightBarButtonItem = clearAllButton
        }

        private func configureTableView() {
            tableView.translatesAutoresizingMaskIntoConstraints = false
            tableView.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.sessionArchivesTable
            tableView.backgroundColor = ConsoleDockUIColors.background
            tableView.separatorColor = ConsoleDockUIColors.separator
            tableView.dataSource = self
            tableView.delegate = self
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 72
            view.addSubview(tableView)

            NSLayoutConstraint.activate([
                tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }

        private func configureEmptyStateLabel() {
            emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
            emptyStateLabel.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.sessionArchivesEmptyState
            emptyStateLabel.font = .preferredFont(forTextStyle: .body)
            emptyStateLabel.textColor = ConsoleDockUIColors.secondaryText
            emptyStateLabel.textAlignment = .center
            emptyStateLabel.numberOfLines = 0
            view.addSubview(emptyStateLabel)

            NSLayoutConstraint.activate([
                emptyStateLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
                emptyStateLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
                emptyStateLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
            ])
        }

        private func reloadArchives() {
            do {
                archives = try ConsoleDock.sessionArchives()
                lastErrorMessage = nil
            } catch {
                archives = []
                lastErrorMessage = "Saved session archives are unavailable."
                ConsoleDock.error("Session archive list failed: \(error)")
            }
            clearAllButton?.isEnabled = !archives.isEmpty
            updateEmptyState()
            tableView.reloadData()
        }

        private func updateEmptyState() {
            let message = lastErrorMessage ?? (archives.isEmpty ? "No saved session archives." : nil)
            emptyStateLabel.text = message
            emptyStateLabel.accessibilityLabel = message
            emptyStateLabel.isHidden = message == nil
        }

        @objc private func confirmClearAll() {
            guard !archives.isEmpty else { return }
            let alert = UIAlertController(
                title: "Clear Saved Archives?",
                message: "This removes all ConsoleDock session archives stored in this app.",
                preferredStyle: .alert
            )
            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            cancel.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.cancelClearSessionArchivesButton
            alert.addAction(cancel)
            let clear = UIAlertAction(title: "Clear All", style: .destructive) { [weak self] _ in
                self?.clearAllArchives()
            }
            clear.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.confirmClearSessionArchivesButton
            alert.addAction(clear)
            present(alert, animated: true)
        }

        private func clearAllArchives() {
            do {
                try ConsoleDock.clearSessionArchives()
            } catch {
                ConsoleDock.error("Session archive clear failed: \(error)")
            }
            reloadArchives()
        }

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            archives.count
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let reuseIdentifier = "ConsoleDockSessionArchiveCell"
            let cell =
                tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)
                ?? UITableViewCell(style: .subtitle, reuseIdentifier: reuseIdentifier)
            let archive = archives[indexPath.row]
            cell.backgroundColor = ConsoleDockUIColors.background
            cell.selectionStyle = .default
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.font = .preferredFont(forTextStyle: .body)
            cell.textLabel?.textColor = ConsoleDockUIColors.primaryText
            cell.textLabel?.text = archive.title
            cell.detailTextLabel?.numberOfLines = 0
            cell.detailTextLabel?.font = ConsoleDockFonts.monospace(size: 10, weight: .regular)
            cell.detailTextLabel?.textColor = ConsoleDockUIColors.secondaryText
            cell.detailTextLabel?.text = detailText(for: archive)
            return cell
        }

        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            guard archives.indices.contains(indexPath.row) else { return }
            let archive = archives[indexPath.row]
            let detailController = ConsoleDockSessionArchiveDetailViewController(archive: archive) { [weak self] in
                self?.reloadArchives()
            }
            navigationController?.pushViewController(detailController, animated: true)
            tableView.deselectRow(at: indexPath, animated: true)
        }

        private func detailText(for archive: ConsoleDock.SessionArchive) -> String {
            var parts = [
                "\(archive.entryCount) entries",
                "session \(archive.sourceSessionIdentifier)"
            ]
            if archive.isReportTruncated {
                parts.append("truncated")
            }
            if let note = archive.note {
                parts.append(note)
            }
            return parts.joined(separator: "\n")
        }
    }

    final class ConsoleDockSessionArchiveDetailViewController: UIViewController {
        private let archive: ConsoleDock.SessionArchive
        private let onDeleted: () -> Void
        private let metadataLabel = UILabel()
        private let reportTextView = UITextView()

        init(archive: ConsoleDock.SessionArchive, onDeleted: @escaping () -> Void) {
            self.archive = archive
            self.onDeleted = onDeleted
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            title = "Archive Detail"
            view.backgroundColor = ConsoleDockUIColors.background
            configureNavigationItems()
            configureMetadataLabel()
            configureReportTextView()
        }

        private func configureNavigationItems() {
            let deleteButton = UIBarButtonItem(
                title: "Delete",
                style: .plain,
                target: self,
                action: #selector(confirmDelete)
            )
            deleteButton.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.deleteSessionArchiveButton

            let shareButton = UIBarButtonItem(
                barButtonSystemItem: .action,
                target: self,
                action: #selector(shareArchive)
            )
            shareButton.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.shareSessionArchiveButton

            let copyButton = UIBarButtonItem(
                title: "Copy",
                style: .plain,
                target: self,
                action: #selector(copyArchive)
            )
            copyButton.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.copySessionArchiveButton

            navigationItem.rightBarButtonItems = [deleteButton, shareButton, copyButton]
        }

        private func configureMetadataLabel() {
            metadataLabel.translatesAutoresizingMaskIntoConstraints = false
            metadataLabel.numberOfLines = 0
            metadataLabel.font = ConsoleDockFonts.monospace(size: 11, weight: .regular)
            metadataLabel.textColor = ConsoleDockUIColors.secondaryText
            metadataLabel.backgroundColor = ConsoleDockUIColors.panel
            metadataLabel.layer.cornerRadius = 6
            metadataLabel.layer.masksToBounds = true
            metadataLabel.text = metadataText()
            view.addSubview(metadataLabel)
        }

        private func configureReportTextView() {
            reportTextView.translatesAutoresizingMaskIntoConstraints = false
            reportTextView.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.sessionArchiveDetailText
            reportTextView.backgroundColor = UIColor(white: 0.04, alpha: 1)
            reportTextView.textColor = ConsoleDockUIColors.primaryText
            reportTextView.font = ConsoleDockFonts.monospace(size: 12, weight: .regular)
            reportTextView.isEditable = false
            reportTextView.alwaysBounceVertical = true
            reportTextView.text = archive.reportText
            view.addSubview(reportTextView)

            NSLayoutConstraint.activate([
                metadataLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
                metadataLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
                metadataLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
                reportTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
                reportTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
                reportTextView.topAnchor.constraint(equalTo: metadataLabel.bottomAnchor, constant: 12),
                reportTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
            ])
        }

        private func metadataText() -> String {
            var lines = [
                "Archive ID: \(archive.id)",
                "Created: \(ConsoleDockSnapshotFormatter.timestampText(archive.createdAt))",
                "Source Session: \(archive.sourceSessionIdentifier)",
                "Entry Count: \(archive.entryCount)",
                "Report Characters: \(archive.reportCharacterCount)",
                "Truncated: \(archive.isReportTruncated)"
            ]
            if let startedAt = archive.sourceSessionStartedAt {
                lines.append("Source Started: \(ConsoleDockSnapshotFormatter.timestampText(startedAt))")
            }
            if let note = archive.note {
                lines.append("Note: \(note)")
            }
            return lines.joined(separator: "\n")
        }

        @objc private func copyArchive() {
            UIPasteboard.general.string = archive.reportText
            UIAccessibility.post(notification: .announcement, argument: "Copied session archive")
        }

        @objc private func shareArchive() {
            let activityItems: [Any]
            let temporaryFileURL: URL?
            do {
                let fileURL = try ConsoleDockIssueReportFileExporter.makeTemporaryReportFile(
                    reportText: archive.reportText,
                    generatedAt: archive.createdAt
                )
                activityItems = [fileURL]
                temporaryFileURL = fileURL
            } catch {
                ConsoleDock.error("Session archive file export failed: \(error)")
                activityItems = [archive.reportText]
                temporaryFileURL = nil
            }

            let activityController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            activityController.completionWithItemsHandler = { _, _, _, _ in
                guard let temporaryFileURL else { return }
                try? FileManager.default.removeItem(at: temporaryFileURL)
            }
            present(activityController, animated: true)
        }

        @objc private func confirmDelete() {
            let alert = UIAlertController(
                title: "Delete Saved Archive?",
                message: archive.title,
                preferredStyle: .alert
            )
            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            cancel.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.cancelDeleteSessionArchiveButton
            alert.addAction(cancel)
            let delete = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                self?.deleteArchive()
            }
            delete.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.confirmDeleteSessionArchiveButton
            alert.addAction(delete)
            present(alert, animated: true)
        }

        private func deleteArchive() {
            do {
                try ConsoleDock.deleteSessionArchive(id: archive.id)
            } catch {
                ConsoleDock.error("Session archive delete failed: \(error)")
            }
            onDeleted()
            navigationController?.popViewController(animated: true)
        }
    }
#endif

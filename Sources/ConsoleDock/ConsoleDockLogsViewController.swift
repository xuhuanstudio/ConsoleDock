#if canImport(UIKit)
    import ConsoleDockCore
    import UIKit

    final class ConsoleDockLogsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,
        UISearchResultsUpdating, UISearchBarDelegate
    {
        var navigationItemsDidChange: (([UIBarButtonItem]) -> Void)?

        private let tableView = UITableView(frame: .zero, style: .plain)
        private let searchController = UISearchController(searchResultsController: nil)
        private let levelSegmentedControl = UISegmentedControl(
            items: ConsoleDockEntryFilter.LevelScope.allCases.map(\.title)
        )
        private let inlineActionStackView = UIStackView()
        private let markInlineButton = UIButton(type: .system)
        private let jumpInlineButton = UIButton(type: .system)
        private let statusLabel = UILabel()
        private let emptyStateLabel = UILabel()
        private var liveUpdateBuffer = ConsoleDockLiveUpdateBuffer()
        private var visibleEntries: [ConsoleDock.LogEntry] = []
        private var searchQuery = ""
        private var sourceScope = ConsoleDockEntryFilter.SourceScope.all
        private var levelScope = ConsoleDockEntryFilter.LevelScope.all
        private var focusedEntryID: UInt64?
        private var observer: ConsoleDockEntriesObserver?
        private var diagnosticsObserver: NSObjectProtocol?
        private var pauseButton: UIBarButtonItem?
        private var shareButton: UIBarButtonItem?
        private var clearButton: UIBarButtonItem?
        private let formatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSS"
            return formatter
        }()

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = ConsoleDockUIColors.background
            configureSearchController()
            configureLevelSegmentedControl()
            configureInlineActionStackView()
            configureStatusLabel()
            configureTableView()
            configureEmptyStateLabel()
            configureNavigationItems()
            observer = ConsoleDockEntriesObserver(deliveryQueue: .main) { [weak self] snapshot in
                self?.receive(snapshot: snapshot)
            }
            diagnosticsObserver = NotificationCenter.default.addObserver(
                forName: ConsoleDock.diagnosticsDidChangeNotification,
                object: CDKConsoleDock.self,
                queue: .main
            ) { [weak self] _ in
                self?.updateStatusHeader()
            }
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            updateStatusHeader()
            publishNavigationItems()
        }

        deinit {
            observer?.invalidate()
            if let diagnosticsObserver {
                NotificationCenter.default.removeObserver(diagnosticsObserver)
            }
        }

        func activateSearch(in navigationItem: UINavigationItem) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
            publishNavigationItems()
        }

        func deactivateSearch() {
            searchController.isActive = false
        }

        private func configureNavigationItems() {
            let shareButton = UIBarButtonItem(
                barButtonSystemItem: .action,
                target: self,
                action: #selector(showShareOptions)
            )
            shareButton.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.shareButton
            shareButton.isEnabled = false
            self.shareButton = shareButton

            let clearButton = UIBarButtonItem(
                title: "Clear",
                style: .plain,
                target: self,
                action: #selector(clear)
            )
            clearButton.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.clearButton
            self.clearButton = clearButton

            let pauseButton = makePauseButton()
            self.pauseButton = pauseButton
            publishNavigationItems()
        }

        private func publishNavigationItems() {
            navigationItemsDidChange?([clearButton, shareButton, pauseButton].compactMap { $0 })
        }

        private func configureSearchController() {
            searchController.searchResultsUpdater = self
            searchController.obscuresBackgroundDuringPresentation = false
            searchController.searchBar.placeholder = "Search, level:error, source:stderr"
            searchController.searchBar.scopeButtonTitles = ConsoleDockEntryFilter.SourceScope.allCases.map(\.title)
            searchController.searchBar.delegate = self
            searchController.searchBar.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.searchBar
            definesPresentationContext = true
        }

        private func configureLevelSegmentedControl() {
            levelSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
            levelSegmentedControl.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.levelFilter
            levelSegmentedControl.selectedSegmentIndex = ConsoleDockEntryFilter.LevelScope.all.rawValue
            ConsoleDockSegmentedControlStyle.applyDarkPanelStyle(to: levelSegmentedControl)
            levelSegmentedControl.addTarget(self, action: #selector(levelScopeDidChange), for: .valueChanged)
            view.addSubview(levelSegmentedControl)
        }

        private func configureInlineActionStackView() {
            inlineActionStackView.translatesAutoresizingMaskIntoConstraints = false
            inlineActionStackView.axis = .horizontal
            inlineActionStackView.spacing = 8
            inlineActionStackView.distribution = .fillEqually
            view.addSubview(inlineActionStackView)

            configureInlineButton(
                markInlineButton,
                title: "Mark",
                accessibilityIdentifier: ConsoleDockAccessibilityIdentifiers.markButton,
                action: #selector(showMarkerPrompt)
            )
            configureInlineButton(
                jumpInlineButton,
                title: "Jump",
                accessibilityIdentifier: ConsoleDockAccessibilityIdentifiers.jumpButton,
                action: #selector(showJumpOptions)
            )
            jumpInlineButton.isEnabled = false
        }

        private func configureInlineButton(
            _ button: UIButton,
            title: String,
            accessibilityIdentifier: String,
            action: Selector
        ) {
            button.translatesAutoresizingMaskIntoConstraints = false
            button.accessibilityIdentifier = accessibilityIdentifier
            button.setTitle(title, for: .normal)
            button.setTitleColor(ConsoleDockUIColors.primaryText, for: .normal)
            button.setTitleColor(ConsoleDockUIColors.secondaryText, for: .disabled)
            button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
            button.backgroundColor = ConsoleDockUIColors.panel
            button.layer.cornerRadius = 6
            button.layer.borderColor = ConsoleDockUIColors.separator.cgColor
            button.layer.borderWidth = 1
            button.addTarget(self, action: action, for: .touchUpInside)
            inlineActionStackView.addArrangedSubview(button)
        }

        private func configureStatusLabel() {
            statusLabel.translatesAutoresizingMaskIntoConstraints = false
            statusLabel.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.status
            statusLabel.isAccessibilityElement = true
            statusLabel.numberOfLines = 0
            statusLabel.font = ConsoleDockFonts.monospace(size: 10, weight: .regular)
            statusLabel.textColor = ConsoleDockUIColors.secondaryText
            statusLabel.backgroundColor = ConsoleDockUIColors.panel
            statusLabel.layer.cornerRadius = 6
            statusLabel.layer.masksToBounds = true
            updateStatusLabelText(
                ConsoleDockDiagnosticsFormatter.statusText(
                    diagnostics: ConsoleDock.diagnostics,
                    visibleEntryCount: 0,
                    isPaused: false
                )
            )
            view.addSubview(statusLabel)
        }

        private func configureTableView() {
            tableView.translatesAutoresizingMaskIntoConstraints = false
            tableView.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.entriesTable
            tableView.backgroundColor = ConsoleDockUIColors.background
            tableView.separatorColor = ConsoleDockUIColors.separator
            tableView.dataSource = self
            tableView.delegate = self
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 54
            view.addSubview(tableView)

            NSLayoutConstraint.activate([
                levelSegmentedControl.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
                levelSegmentedControl.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
                levelSegmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
                levelSegmentedControl.heightAnchor.constraint(equalToConstant: 32),
                inlineActionStackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
                inlineActionStackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
                inlineActionStackView.topAnchor.constraint(equalTo: levelSegmentedControl.bottomAnchor, constant: 8),
                inlineActionStackView.heightAnchor.constraint(equalToConstant: 32),
                statusLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
                statusLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
                statusLabel.topAnchor.constraint(equalTo: inlineActionStackView.bottomAnchor, constant: 8),
                tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                tableView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
                tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }

        private func configureEmptyStateLabel() {
            emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
            emptyStateLabel.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.emptyState
            emptyStateLabel.font = .preferredFont(forTextStyle: .body)
            emptyStateLabel.textColor = ConsoleDockUIColors.secondaryText
            emptyStateLabel.textAlignment = .center
            emptyStateLabel.numberOfLines = 0
            emptyStateLabel.isHidden = true
            view.addSubview(emptyStateLabel)

            NSLayoutConstraint.activate([
                emptyStateLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
                emptyStateLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
                emptyStateLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
            ])
        }

        private func receive(snapshot: [ConsoleDock.LogEntry]) {
            if liveUpdateBuffer.receive(snapshot: snapshot) {
                reloadVisibleEntries(scrollToBottom: true)
            } else {
                updateStatusHeader()
            }
        }

        private func reloadVisibleEntries(scrollToBottom: Bool) {
            visibleEntries = ConsoleDockEntryFilter.filteredEntries(
                liveUpdateBuffer.displayedEntries,
                query: searchQuery,
                sourceScope: sourceScope,
                levelScope: levelScope
            )
            shareButton?.isEnabled = !visibleEntries.isEmpty || !ConsoleDock.entries.isEmpty
            jumpInlineButton.isEnabled = !visibleEntries.isEmpty
            updateStatusHeader()
            updateEmptyState()
            tableView.reloadData()
            guard scrollToBottom, !visibleEntries.isEmpty else { return }
            let indexPath = IndexPath(row: visibleEntries.count - 1, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        }

        @objc private func clear() {
            ConsoleDock.clear()
            if ConsoleDock.entries.isEmpty {
                liveUpdateBuffer.replaceDisplayedEntries([])
                reloadVisibleEntries(scrollToBottom: false)
            }
        }

        @objc private func showShareOptions() {
            let alert = UIAlertController(title: "Share Logs", message: nil, preferredStyle: .actionSheet)
            let visibleAction = UIAlertAction(title: "Share Visible Logs", style: .default) { [weak self] _ in
                self?.share(entries: self?.visibleEntries ?? [], visibleEntryCount: self?.visibleEntries.count)
            }
            visibleAction.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.shareVisibleLogs
            visibleAction.isEnabled = !visibleEntries.isEmpty
            alert.addAction(visibleAction)

            let allEntries = ConsoleDock.entries
            let allAction = UIAlertAction(title: "Share All Logs", style: .default) { [weak self] _ in
                self?.share(entries: ConsoleDock.entries, visibleEntryCount: nil)
            }
            allAction.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.shareAllLogs
            allAction.isEnabled = !allEntries.isEmpty
            alert.addAction(allAction)
            let reportAction = UIAlertAction(title: "Share Issue Report", style: .default) { [weak self] _ in
                self?.shareIssueReport()
            }
            reportAction.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.shareIssueReport
            alert.addAction(reportAction)
            let copyReportAction = UIAlertAction(title: "Copy Issue Report", style: .default) { _ in
                ConsoleDockPasteboard.copy(ConsoleDock.issueReportText())
            }
            copyReportAction.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.copyIssueReport
            alert.addAction(copyReportAction)
            let saveArchiveAction = UIAlertAction(title: "Save Session Archive", style: .default) { [weak self] _ in
                self?.saveSessionArchive()
            }
            saveArchiveAction.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.saveSessionArchive
            alert.addAction(saveArchiveAction)
            let savedArchivesAction = UIAlertAction(title: "Saved Session Archives", style: .default) { [weak self] _ in
                self?.showSavedSessionArchives()
            }
            savedArchivesAction.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.savedSessionArchives
            alert.addAction(savedArchivesAction)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.popoverPresentationController?.barButtonItem = shareButton
            present(alert, animated: true)
        }

        private func share(entries: [ConsoleDock.LogEntry], visibleEntryCount: Int?) {
            guard !entries.isEmpty else { return }
            let snapshot = ConsoleDockSnapshotFormatter.snapshotText(
                entries: entries,
                diagnostics: ConsoleDock.diagnostics,
                visibleEntryCount: visibleEntryCount
            )
            let activityController = UIActivityViewController(activityItems: [snapshot], applicationActivities: nil)
            activityController.popoverPresentationController?.barButtonItem = shareButton
            present(activityController, animated: true)
        }

        private func shareIssueReport() {
            let report = ConsoleDock.issueReportText()
            let activityItems: [Any]
            let temporaryFileURL: URL?
            do {
                let fileURL = try ConsoleDockIssueReportFileExporter.makeTemporaryReportFile(reportText: report)
                activityItems = [fileURL]
                temporaryFileURL = fileURL
            } catch {
                ConsoleDock.error("Issue report file export failed: \(error)")
                activityItems = [report]
                temporaryFileURL = nil
            }

            let activityController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            activityController.completionWithItemsHandler = { _, _, _, _ in
                guard let temporaryFileURL else { return }
                try? FileManager.default.removeItem(at: temporaryFileURL)
            }
            activityController.popoverPresentationController?.barButtonItem = shareButton
            present(activityController, animated: true)
        }

        private func saveSessionArchive() {
            do {
                let archive = try ConsoleDock.saveSessionArchive()
                UIAccessibility.post(notification: .announcement, argument: "Saved session archive")
                showSavedArchiveAlert(archive)
            } catch {
                ConsoleDock.error("Session archive save failed: \(error)")
                showArchiveErrorAlert(error)
            }
        }

        private func showSavedArchiveAlert(_ archive: ConsoleDock.SessionArchive) {
            let alert = UIAlertController(
                title: "Saved Session Archive",
                message: archive.title,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            let viewAction = UIAlertAction(title: "View Archives", style: .default) { [weak self] _ in
                self?.showSavedSessionArchives()
            }
            alert.addAction(viewAction)
            present(alert, animated: true)
        }

        private func showArchiveErrorAlert(_ error: Error) {
            let alert = UIAlertController(
                title: "Archive Save Failed",
                message: "\(error)",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }

        private func showSavedSessionArchives() {
            navigationController?.pushViewController(ConsoleDockSessionArchivesViewController(), animated: true)
        }

        @objc private func showJumpOptions() {
            let alert = UIAlertController(title: "Jump", message: nil, preferredStyle: .actionSheet)
            let latestAction = UIAlertAction(title: "Latest Visible Log", style: .default) { [weak self] _ in
                self?.scrollToLatestVisibleEntry()
            }
            latestAction.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.jumpLatestLog
            latestAction.isEnabled = !visibleEntries.isEmpty
            alert.addAction(latestAction)

            let firstErrorAction = UIAlertAction(title: "First Visible Error", style: .default) { [weak self] _ in
                self?.scrollToFirstVisibleError()
            }
            firstErrorAction.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.jumpFirstError
            firstErrorAction.isEnabled = firstVisibleErrorIndex() != nil
            alert.addAction(firstErrorAction)

            let previousErrorAction = UIAlertAction(title: "Previous Visible Error", style: .default) { [weak self] _ in
                self?.scrollToPreviousVisibleError()
            }
            previousErrorAction.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.jumpPreviousError
            previousErrorAction.isEnabled = previousVisibleErrorIndex() != nil
            alert.addAction(previousErrorAction)

            let nextErrorAction = UIAlertAction(title: "Next Visible Error", style: .default) { [weak self] _ in
                self?.scrollToNextVisibleError()
            }
            nextErrorAction.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.jumpNextError
            nextErrorAction.isEnabled = nextVisibleErrorIndex() != nil
            alert.addAction(nextErrorAction)

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.popoverPresentationController?.sourceView = jumpInlineButton
            alert.popoverPresentationController?.sourceRect = jumpInlineButton.bounds
            present(alert, animated: true)
        }

        private func scrollToLatestVisibleEntry() {
            guard !visibleEntries.isEmpty else { return }
            scrollToVisibleEntry(at: visibleEntries.count - 1)
        }

        private func scrollToFirstVisibleError() {
            guard let index = firstVisibleErrorIndex() else { return }
            scrollToVisibleEntry(at: index)
        }

        private func scrollToPreviousVisibleError() {
            guard let index = previousVisibleErrorIndex() else { return }
            scrollToVisibleEntry(at: index)
        }

        private func scrollToNextVisibleError() {
            guard let index = nextVisibleErrorIndex() else { return }
            scrollToVisibleEntry(at: index)
        }

        private func firstVisibleErrorIndex() -> Int? {
            visibleEntries.firstIndex { entry in
                isErrorOrFault(entry)
            }
        }

        private func previousVisibleErrorIndex() -> Int? {
            let currentIndex = currentFocusedVisibleIndex() ?? visibleEntries.count
            return visibleEntries.indices.reversed().first { index in
                index < currentIndex && isErrorOrFault(visibleEntries[index])
            }
        }

        private func nextVisibleErrorIndex() -> Int? {
            let currentIndex = currentFocusedVisibleIndex() ?? -1
            return visibleEntries.indices.first { index in
                index > currentIndex && isErrorOrFault(visibleEntries[index])
            }
        }

        private func currentFocusedVisibleIndex() -> Int? {
            guard let focusedEntryID else { return nil }
            return visibleEntries.firstIndex { $0.id == focusedEntryID }
        }

        private func isErrorOrFault(_ entry: ConsoleDock.LogEntry) -> Bool {
            entry.level == .error || entry.level == .fault
        }

        private func scrollToVisibleEntry(at index: Int) {
            guard visibleEntries.indices.contains(index) else { return }
            focusedEntryID = visibleEntries[index].id
            let indexPath = IndexPath(row: index, section: 0)
            tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            tableView.deselectRow(at: indexPath, animated: true)
        }

        @objc private func showMarkerPrompt() {
            guard ConsoleDock.isRunning else { return }
            let alert = UIAlertController(
                title: "Add Marker",
                message: nil,
                preferredStyle: .alert
            )
            alert.addTextField { textField in
                textField.placeholder = "What just happened?"
                textField.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.markerTextField
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            let addAction = UIAlertAction(title: "Add Marker", style: .default) { _ in
                ConsoleDock.mark(alert.textFields?.first?.text ?? "")
            }
            addAction.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.addMarkerButton
            alert.addAction(addAction)
            present(alert, animated: true)
        }

        @objc private func toggleLiveUpdates() {
            if liveUpdateBuffer.isPaused {
                liveUpdateBuffer.resume(latestEntries: ConsoleDock.entries)
                updatePauseButton()
                reloadVisibleEntries(scrollToBottom: true)
            } else {
                liveUpdateBuffer.pause()
                updatePauseButton()
                updateStatusHeader()
            }
        }

        private func makePauseButton() -> UIBarButtonItem {
            let item = UIBarButtonItem(
                barButtonSystemItem: liveUpdateBuffer.isPaused ? .play : .pause,
                target: self,
                action: #selector(toggleLiveUpdates)
            )
            item.accessibilityLabel = liveUpdateBuffer.isPaused ? "Resume Live Updates" : "Pause Live Updates"
            item.accessibilityIdentifier =
                liveUpdateBuffer.isPaused
                ? ConsoleDockAccessibilityIdentifiers.resumeLiveButton
                : ConsoleDockAccessibilityIdentifiers.pauseLiveButton
            return item
        }

        private func updatePauseButton() {
            let pauseButton = makePauseButton()
            self.pauseButton = pauseButton
            publishNavigationItems()
        }

        func updateSearchResults(for searchController: UISearchController) {
            searchQuery = searchController.searchBar.text ?? ""
            reloadVisibleEntries(scrollToBottom: false)
        }

        func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
            sourceScope = ConsoleDockEntryFilter.SourceScope(rawValue: selectedScope) ?? .all
            reloadVisibleEntries(scrollToBottom: false)
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchController.isActive = false
        }

        @objc private func levelScopeDidChange() {
            levelScope = ConsoleDockEntryFilter.LevelScope(rawValue: levelSegmentedControl.selectedSegmentIndex) ?? .all
            reloadVisibleEntries(scrollToBottom: false)
        }

        private func updateStatusHeader() {
            updateStatusLabelText(
                ConsoleDockDiagnosticsFormatter.statusText(
                    diagnostics: ConsoleDock.diagnostics,
                    visibleEntryCount: visibleEntries.count,
                    isPaused: liveUpdateBuffer.isPaused
                )
            )
        }

        private func updateStatusLabelText(_ text: String) {
            statusLabel.text = text
            statusLabel.accessibilityLabel = text
        }

        private func updateEmptyState() {
            let message: String?
            if liveUpdateBuffer.displayedEntries.isEmpty {
                message = "No logs yet."
            } else if visibleEntries.isEmpty {
                message = "No logs match the current filters."
            } else {
                message = nil
            }
            emptyStateLabel.text = message
            emptyStateLabel.accessibilityLabel = message
            emptyStateLabel.isHidden = message == nil
        }

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            visibleEntries.count
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let reuseIdentifier = "ConsoleDockEntryCell"
            let cell =
                tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)
                ?? UITableViewCell(style: .subtitle, reuseIdentifier: reuseIdentifier)
            let entry = visibleEntries[indexPath.row]
            cell.backgroundColor = ConsoleDockUIColors.background
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.font = ConsoleDockFonts.monospace(size: 12, weight: .regular)
            cell.textLabel?.textColor = ConsoleDockUIColors.primaryText
            cell.textLabel?.text = entry.message
            cell.selectionStyle = .default
            cell.accessoryType = .disclosureIndicator
            cell.detailTextLabel?.font = ConsoleDockFonts.monospace(size: 10, weight: .regular)
            cell.detailTextLabel?.textColor = ConsoleDockUIColors.level(entry.level)
            cell.detailTextLabel?.text =
                "\(formatter.string(from: entry.timestamp))  \(entry.source.consoleDockLabel)  \(entry.level.consoleDockLabel)"
            return cell
        }

        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            guard visibleEntries.indices.contains(indexPath.row) else { return }
            let entry = visibleEntries[indexPath.row]
            focusedEntryID = entry.id
            let detailController = ConsoleDockLogDetailViewController(entry: entry)
            navigationController?.pushViewController(detailController, animated: true)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
#endif

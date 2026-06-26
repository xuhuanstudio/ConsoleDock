#if canImport(UIKit)
    import ConsoleDockCore
    import UIKit

    final class ConsoleDockTimelineViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
        var navigationItemsDidChange: (([UIBarButtonItem]) -> Void)?

        private let tableView = UITableView(frame: .zero, style: .plain)
        private let emptyStateLabel = UILabel()
        private var events: [ConsoleDockTimelineEvent] = []
        private var latestEntries: [ConsoleDock.LogEntry] = []
        private var entriesObserver: ConsoleDockEntriesObserver?
        private var actionsObserver: NSObjectProtocol?
        private var refreshButton: UIBarButtonItem?
        private let formatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSS"
            return formatter
        }()

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = ConsoleDockUIColors.background
            configureTableView()
            configureEmptyStateLabel()
            configureNavigationItems()
            entriesObserver = ConsoleDockEntriesObserver(deliveryQueue: .main) { [weak self] snapshot in
                self?.receive(entries: snapshot)
            }
            actionsObserver = NotificationCenter.default.addObserver(
                forName: .consoleDockDebugActionsDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.reloadTimeline()
            }
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            reloadTimeline()
            publishNavigationItems()
        }

        deinit {
            entriesObserver?.invalidate()
            if let actionsObserver {
                NotificationCenter.default.removeObserver(actionsObserver)
            }
        }

        func activate() {
            reloadTimeline()
            publishNavigationItems()
        }

        func deactivate() {}

        private func configureNavigationItems() {
            let refreshButton = UIBarButtonItem(
                barButtonSystemItem: .refresh,
                target: self,
                action: #selector(refreshTimeline)
            )
            refreshButton.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.timelineRefreshButton
            self.refreshButton = refreshButton
            publishNavigationItems()
        }

        private func publishNavigationItems() {
            navigationItemsDidChange?([refreshButton].compactMap { $0 })
        }

        private func configureTableView() {
            tableView.translatesAutoresizingMaskIntoConstraints = false
            tableView.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.timelineTable
            tableView.backgroundColor = ConsoleDockUIColors.background
            tableView.separatorColor = ConsoleDockUIColors.separator
            tableView.dataSource = self
            tableView.delegate = self
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 64
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
            emptyStateLabel.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.timelineEmptyState
            emptyStateLabel.font = .preferredFont(forTextStyle: .body)
            emptyStateLabel.textColor = ConsoleDockUIColors.secondaryText
            emptyStateLabel.textAlignment = .center
            emptyStateLabel.numberOfLines = 0
            emptyStateLabel.text = "No timeline events yet."
            emptyStateLabel.accessibilityLabel = "No timeline events yet."
            emptyStateLabel.isHidden = true
            view.addSubview(emptyStateLabel)

            NSLayoutConstraint.activate([
                emptyStateLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
                emptyStateLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
                emptyStateLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
            ])
        }

        private func receive(entries: [ConsoleDock.LogEntry]) {
            latestEntries = entries
            reloadTimeline()
        }

        @objc private func refreshTimeline() {
            latestEntries = ConsoleDock.entries
            reloadTimeline()
        }

        private func reloadTimeline() {
            let entries = latestEntries.isEmpty ? ConsoleDock.entries : latestEntries
            events = ConsoleDockTimelineBuilder.events(
                entries: entries,
                actionExecutions: ConsoleDock.actionExecutionHistory
            )
            tableView.reloadData()
            updateEmptyState()
        }

        private func updateEmptyState() {
            emptyStateLabel.isHidden = !events.isEmpty
        }

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            events.count
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let reuseIdentifier = "ConsoleDockTimelineCell"
            let cell =
                tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)
                ?? UITableViewCell(style: .subtitle, reuseIdentifier: reuseIdentifier)
            let event = events[indexPath.row]
            cell.backgroundColor = ConsoleDockUIColors.background
            cell.selectionStyle = .default
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.font = ConsoleDockFonts.monospace(size: 12, weight: .semibold)
            cell.textLabel?.textColor = ConsoleDockUIColors.primaryText
            cell.textLabel?.text = event.title
            cell.detailTextLabel?.numberOfLines = 0
            cell.detailTextLabel?.font = ConsoleDockFonts.monospace(size: 10, weight: .regular)
            cell.detailTextLabel?.textColor = color(for: event)
            cell.detailTextLabel?.text = detailText(for: event)
            return cell
        }

        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            guard events.indices.contains(indexPath.row) else { return }
            let event = events[indexPath.row]
            if let entry = event.logEntry {
                navigationController?.pushViewController(
                    ConsoleDockLogDetailViewController(entry: entry),
                    animated: true
                )
            } else if let execution = event.actionExecution {
                navigationController?.pushViewController(
                    ConsoleDockTimelineActionDetailViewController(execution: execution),
                    animated: true
                )
            }
            tableView.deselectRow(at: indexPath, animated: true)
        }

        private func detailText(for event: ConsoleDockTimelineEvent) -> String {
            var parts = [
                formatter.string(from: event.timestamp),
                event.subtitle
            ]
            if let detail = event.detail {
                parts.append(detail)
            }
            return parts.joined(separator: "\n")
        }

        private func color(for event: ConsoleDockTimelineEvent) -> UIColor {
            switch event.severity {
            case .neutral:
                return ConsoleDockUIColors.secondaryText
            case .success:
                return UIColor(red: 0.42, green: 0.84, blue: 0.54, alpha: 1)
            case .warning:
                return ConsoleDockUIColors.level(.warning)
            case .error:
                return ConsoleDockUIColors.level(.error)
            }
        }
    }
#endif

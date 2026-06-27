#if canImport(UIKit)
    import UIKit

    final class ConsoleDockContextViewController: UIViewController, UITableViewDataSource {
        var navigationItemsDidChange: (([UIBarButtonItem]) -> Void)?

        private let tableView = UITableView(frame: .zero, style: .grouped)
        private let emptyStateLabel = UILabel()
        private var sections: [ConsoleDock.AppContextSection] = []
        private var lastHealthSnapshot = ConsoleDockIntegrationDiagnosisFormatter.snapshot()
        private var appContextSections: [ConsoleDock.AppContextSection] = []
        private var copyDiagnosisButton: UIBarButtonItem?
        private var refreshButton: UIBarButtonItem?

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = ConsoleDockUIColors.background
            configureNavigationItems()
            configureTableView()
            configureEmptyStateLabel()
            reloadContext()
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            reloadContext()
            publishNavigationItems()
        }

        func activate() {
            reloadContext()
            publishNavigationItems()
        }

        func deactivate() {}

        private func configureNavigationItems() {
            let copyDiagnosisButton = UIBarButtonItem(
                title: "Copy",
                style: .plain,
                target: self,
                action: #selector(copyIntegrationDiagnosis)
            )
            copyDiagnosisButton.accessibilityIdentifier =
                ConsoleDockAccessibilityIdentifiers.contextCopyDiagnosisButton
            copyDiagnosisButton.accessibilityLabel = "Copy Integration Diagnosis"
            self.copyDiagnosisButton = copyDiagnosisButton

            let refreshButton = UIBarButtonItem(
                barButtonSystemItem: .refresh,
                target: self,
                action: #selector(refreshContext)
            )
            refreshButton.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.contextRefreshButton
            self.refreshButton = refreshButton
            publishNavigationItems()
        }

        private func publishNavigationItems() {
            navigationItemsDidChange?([copyDiagnosisButton, refreshButton].compactMap { $0 })
        }

        private func configureTableView() {
            tableView.translatesAutoresizingMaskIntoConstraints = false
            tableView.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.contextTable
            tableView.backgroundColor = ConsoleDockUIColors.background
            tableView.separatorColor = ConsoleDockUIColors.separator
            tableView.dataSource = self
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 54
            tableView.tableFooterView = UIView()
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
            emptyStateLabel.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.emptyState
            emptyStateLabel.font = .preferredFont(forTextStyle: .body)
            emptyStateLabel.textColor = ConsoleDockUIColors.secondaryText
            emptyStateLabel.textAlignment = .center
            emptyStateLabel.numberOfLines = 0
            emptyStateLabel.text = "No app context registered."
            emptyStateLabel.accessibilityLabel = emptyStateLabel.text
            view.addSubview(emptyStateLabel)

            NSLayoutConstraint.activate([
                emptyStateLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
                emptyStateLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
                emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        }

        @objc private func refreshContext() {
            reloadContext()
        }

        @objc private func copyIntegrationDiagnosis() {
            ConsoleDockPasteboard.copy(
                ConsoleDockIntegrationDiagnosisFormatter.diagnosisText(snapshot: lastHealthSnapshot)
            )
            let alert = UIAlertController(
                title: "Copied Integration Diagnosis",
                message: nil,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }

        private func reloadContext() {
            appContextSections = ConsoleDock.appContext
            lastHealthSnapshot = ConsoleDockIntegrationDiagnosisFormatter.snapshot(
                appContext: appContextSections
            )
            let healthSection = ConsoleDockIntegrationDiagnosisFormatter.healthSection(
                snapshot: lastHealthSnapshot
            )
            sections = [healthSection] + appContextSections
            emptyStateLabel.isHidden = !sections.isEmpty
            tableView.reloadData()
        }

        func numberOfSections(in tableView: UITableView) -> Int {
            sections.count
        }

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            sections[section].items.count
        }

        func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            sections[section].title
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let reuseIdentifier = "ConsoleDockContextCell"
            let cell =
                tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)
                ?? UITableViewCell(style: .subtitle, reuseIdentifier: reuseIdentifier)
            let item = sections[indexPath.section].items[indexPath.row]
            cell.backgroundColor = ConsoleDockUIColors.background
            cell.selectionStyle = .none
            cell.textLabel?.text = item.key
            cell.textLabel?.font = .preferredFont(forTextStyle: .body)
            cell.textLabel?.textColor = ConsoleDockUIColors.primaryText
            cell.textLabel?.numberOfLines = 0
            cell.detailTextLabel?.text = item.value
            cell.detailTextLabel?.font = ConsoleDockFonts.monospace(size: 11, weight: .regular)
            cell.detailTextLabel?.textColor = ConsoleDockUIColors.secondaryText
            cell.detailTextLabel?.numberOfLines = 0
            cell.accessibilityLabel = "\(item.key): \(item.value)"
            return cell
        }
    }
#endif

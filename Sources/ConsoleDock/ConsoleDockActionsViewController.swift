#if canImport(UIKit)
    import UIKit

    final class ConsoleDockActionsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,
        UISearchBarDelegate
    {
        private struct Section {
            let title: String
            let actions: [ConsoleDockDebugAction]
        }

        private let tableView = UITableView(frame: .zero, style: .grouped)
        private let searchBar = UISearchBar(frame: .zero)
        private let emptyStateLabel = UILabel()
        private var sections: [Section] = []
        private var allActions: [ConsoleDockDebugAction] = []
        private var searchQuery = ""
        private var actionsObserver: NSObjectProtocol?

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = ConsoleDockUIColors.background
            configureSearchController()
            configureTableView()
            configureEmptyStateLabel()
            reloadActions()
            actionsObserver = NotificationCenter.default.addObserver(
                forName: .consoleDockDebugActionsDidChange,
                object: ConsoleDockDebugActionRegistry.shared,
                queue: .main
            ) { [weak self] _ in
                self?.reloadActions()
            }
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            reloadActions()
        }

        deinit {
            if let actionsObserver {
                NotificationCenter.default.removeObserver(actionsObserver)
            }
        }

        func activateSearch(in navigationItem: UINavigationItem) {
            navigationItem.searchController = nil
        }

        func deactivateSearch() {
            searchBar.resignFirstResponder()
            searchBar.text = nil
            searchQuery = ""
            reloadActions()
        }

        private func configureSearchController() {
            searchBar.translatesAutoresizingMaskIntoConstraints = false
            searchBar.placeholder = "Search actions"
            searchBar.delegate = self
            searchBar.searchBarStyle = .minimal
            searchBar.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.actionsSearchBar
            if #available(iOS 13.0, *) {
                searchBar.searchTextField.accessibilityIdentifier =
                    ConsoleDockAccessibilityIdentifiers.actionsSearchBar
            }
            view.addSubview(searchBar)
        }

        private func configureTableView() {
            tableView.translatesAutoresizingMaskIntoConstraints = false
            tableView.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.actionsTable
            tableView.backgroundColor = ConsoleDockUIColors.background
            tableView.separatorColor = ConsoleDockUIColors.separator
            tableView.dataSource = self
            tableView.delegate = self
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 58
            view.addSubview(tableView)

            NSLayoutConstraint.activate([
                searchBar.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
                searchBar.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
                searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
                tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 4),
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
            emptyStateLabel.text = "No debug actions registered."
            view.addSubview(emptyStateLabel)

            NSLayoutConstraint.activate([
                emptyStateLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
                emptyStateLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
                emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        }

        private func reloadActions() {
            allActions = ConsoleDock.debugActions
            let filteredActions = ConsoleDockDebugActionFilter.filteredActions(allActions, query: searchQuery)
            sections = groupedSections(from: filteredActions)
            updateEmptyState()
            tableView.reloadData()
        }

        private func updateEmptyState() {
            let message: String?
            if allActions.isEmpty {
                message = "No debug actions registered."
            } else if sections.isEmpty {
                message = "No debug actions match the current search."
            } else {
                message = nil
            }
            emptyStateLabel.text = message
            emptyStateLabel.accessibilityLabel = message
            emptyStateLabel.isHidden = message == nil
        }

        private func groupedSections(from actions: [ConsoleDockDebugAction]) -> [Section] {
            var sections: [Section] = []
            for action in actions {
                let title = action.group ?? "Actions"
                if let index = sections.firstIndex(where: { $0.title == title }) {
                    var existingActions = sections[index].actions
                    existingActions.append(action)
                    sections[index] = Section(title: title, actions: existingActions)
                } else {
                    sections.append(Section(title: title, actions: [action]))
                }
            }
            return sections
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            searchQuery = searchText
            reloadActions()
        }

        func numberOfSections(in tableView: UITableView) -> Int {
            sections.count
        }

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            sections[section].actions.count
        }

        func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            sections[section].title
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let reuseIdentifier = "ConsoleDockActionCell"
            let cell =
                tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)
                ?? UITableViewCell(style: .subtitle, reuseIdentifier: reuseIdentifier)
            let action = sections[indexPath.section].actions[indexPath.row]
            cell.backgroundColor = UIColor(white: 0.1, alpha: 1)
            cell.textLabel?.textColor =
                action.style == .destructive ? ConsoleDockUIColors.level(.error) : ConsoleDockUIColors.primaryText
            cell.textLabel?.font = .preferredFont(forTextStyle: .body)
            cell.textLabel?.text = action.title
            cell.detailTextLabel?.textColor = ConsoleDockUIColors.secondaryText
            cell.detailTextLabel?.font = .preferredFont(forTextStyle: .footnote)
            cell.detailTextLabel?.numberOfLines = 0
            cell.detailTextLabel?.text = detailText(for: action)
            cell.contentView.alpha = action.isEnabled ? 1 : 0.5
            cell.selectionStyle = action.isEnabled ? .default : .none
            cell.accessoryType = action.parameters.isEmpty ? .none : .disclosureIndicator
            cell.accessibilityHint =
                accessibilityHint(for: action)
            return cell
        }

        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            guard let action = action(at: indexPath) else { return }
            tableView.deselectRow(at: indexPath, animated: true)
            guard action.isEnabled else { return }
            if action.requiresConfirmation {
                confirm(action) { [weak self] in
                    self?.performOrRequestParameters(for: action)
                }
            } else {
                performOrRequestParameters(for: action)
            }
        }

        private func action(at indexPath: IndexPath) -> ConsoleDockDebugAction? {
            guard sections.indices.contains(indexPath.section),
                sections[indexPath.section].actions.indices.contains(indexPath.row)
            else {
                return nil
            }
            return sections[indexPath.section].actions[indexPath.row]
        }

        private func detailText(for action: ConsoleDockDebugAction) -> String {
            var parts: [String] = []
            if let detail = action.detail {
                parts.append(detail)
            }
            if !action.isEnabled {
                parts.append("Disabled")
            }
            if action.style == .destructive {
                parts.append("Destructive")
            }
            if action.requiresConfirmation {
                parts.append("Requires confirmation")
            }
            if !action.parameters.isEmpty {
                let suffix = action.parameters.count == 1 ? "parameter" : "parameters"
                parts.append("\(action.parameters.count) \(suffix)")
            }
            return parts.joined(separator: "\n")
        }

        private func accessibilityHint(for action: ConsoleDockDebugAction) -> String {
            guard action.isEnabled else {
                return "This debug action is disabled."
            }
            if !action.parameters.isEmpty, action.requiresConfirmation {
                return "Requires confirmation, then opens parameter fields before running."
            }
            if !action.parameters.isEmpty {
                return "Opens parameter fields before running."
            }
            if action.requiresConfirmation {
                return "Requires confirmation before running."
            }
            return "Runs this debug action."
        }

        private func performOrRequestParameters(for action: ConsoleDockDebugAction) {
            guard !action.parameters.isEmpty else {
                ConsoleDock.performDebugAction(id: action.id)
                return
            }

            let formController = ConsoleDockActionParameterFormViewController(
                action: action,
                recentParameterValues: ConsoleDock.recentDebugActionParameterValues(actionID: action.id)
            ) { parameterValues in
                ConsoleDock.storeRecentDebugActionParameterValues(actionID: action.id, parameterValues: parameterValues)
                ConsoleDock.performDebugAction(id: action.id, parameterValues: parameterValues)
            }
            navigationController?.pushViewController(formController, animated: true)
        }

        private func confirm(_ action: ConsoleDockDebugAction, onConfirm: @escaping () -> Void) {
            let alert = UIAlertController(
                title: action.title,
                message: action.detail,
                preferredStyle: .alert
            )
            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            cancel.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.cancelActionButton
            alert.addAction(cancel)
            let confirmStyle: UIAlertAction.Style = action.style == .destructive ? .destructive : .default
            let confirm = UIAlertAction(title: "Run Action", style: confirmStyle) { _ in
                onConfirm()
            }
            confirm.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.confirmActionButton
            alert.addAction(confirm)
            present(alert, animated: true)
        }
    }
#endif

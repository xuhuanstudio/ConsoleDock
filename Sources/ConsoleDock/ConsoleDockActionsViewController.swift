#if canImport(UIKit)
    import UIKit

    final class ConsoleDockActionsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
        private struct Section {
            let title: String
            let actions: [ConsoleDockDebugAction]
        }

        private let tableView = UITableView(frame: .zero, style: .grouped)
        private let emptyStateLabel = UILabel()
        private var sections: [Section] = []
        private var actionsObserver: NSObjectProtocol?

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = ConsoleDockUIColors.background
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
            emptyStateLabel.text = "No debug actions registered."
            view.addSubview(emptyStateLabel)

            NSLayoutConstraint.activate([
                emptyStateLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
                emptyStateLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
                emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        }

        private func reloadActions() {
            sections = groupedSections(from: ConsoleDock.debugActions)
            emptyStateLabel.isHidden = !sections.isEmpty
            tableView.reloadData()
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
            cell.accessoryType = .none
            cell.accessibilityHint =
                accessibilityHint(for: action)
            return cell
        }

        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            guard let action = action(at: indexPath) else { return }
            tableView.deselectRow(at: indexPath, animated: true)
            guard action.isEnabled else { return }
            if action.requiresConfirmation {
                confirm(action)
            } else {
                ConsoleDock.performDebugAction(id: action.id)
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
            return parts.joined(separator: "\n")
        }

        private func accessibilityHint(for action: ConsoleDockDebugAction) -> String {
            guard action.isEnabled else {
                return "This debug action is disabled."
            }
            if action.requiresConfirmation {
                return "Requires confirmation before running."
            }
            return "Runs this debug action."
        }

        private func confirm(_ action: ConsoleDockDebugAction) {
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
                ConsoleDock.performDebugAction(id: action.id)
            }
            confirm.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.confirmActionButton
            alert.addAction(confirm)
            present(alert, animated: true)
        }
    }
#endif

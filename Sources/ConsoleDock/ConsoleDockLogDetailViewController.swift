#if canImport(UIKit)
    import UIKit

    final class ConsoleDockLogDetailViewController: UIViewController {
        private let entry: ConsoleDock.LogEntry
        private let metadataLabel = UILabel()
        private let messageTextView = UITextView()

        init(entry: ConsoleDock.LogEntry) {
            self.entry = entry
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            title = "Log Detail"
            view.backgroundColor = ConsoleDockUIColors.background
            configureNavigationItems()
            configureMetadataLabel()
            configureMessageTextView()
        }

        private func configureNavigationItems() {
            let copyEntryButton = UIBarButtonItem(
                title: "Copy Entry",
                style: .plain,
                target: self,
                action: #selector(copyEntry)
            )
            copyEntryButton.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.copyEntryButton

            let copyMessageButton = UIBarButtonItem(
                title: "Copy Message",
                style: .plain,
                target: self,
                action: #selector(copyMessage)
            )
            copyMessageButton.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.copyMessageButton
            navigationItem.rightBarButtonItems = [copyEntryButton, copyMessageButton]
        }

        private func configureMetadataLabel() {
            metadataLabel.translatesAutoresizingMaskIntoConstraints = false
            metadataLabel.numberOfLines = 0
            metadataLabel.font = ConsoleDockFonts.monospace(size: 11, weight: .regular)
            metadataLabel.textColor = ConsoleDockUIColors.secondaryText
            metadataLabel.backgroundColor = ConsoleDockUIColors.panel
            metadataLabel.layer.cornerRadius = 6
            metadataLabel.layer.masksToBounds = true
            metadataLabel.text = ConsoleDockSnapshotFormatter.metadataText(entry)
            view.addSubview(metadataLabel)
        }

        private func configureMessageTextView() {
            messageTextView.translatesAutoresizingMaskIntoConstraints = false
            messageTextView.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.entryDetailMessage
            messageTextView.backgroundColor = UIColor(white: 0.04, alpha: 1)
            messageTextView.textColor = ConsoleDockUIColors.primaryText
            messageTextView.font = ConsoleDockFonts.monospace(size: 12, weight: .regular)
            messageTextView.isEditable = false
            messageTextView.alwaysBounceVertical = true
            messageTextView.text = entry.message
            view.addSubview(messageTextView)

            NSLayoutConstraint.activate([
                metadataLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
                metadataLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
                metadataLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
                messageTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
                messageTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
                messageTextView.topAnchor.constraint(equalTo: metadataLabel.bottomAnchor, constant: 12),
                messageTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
            ])
        }

        @objc private func copyMessage() {
            ConsoleDockPasteboard.copy(entry.message)
            UIAccessibility.post(notification: .announcement, argument: "Copied log message")
        }

        @objc private func copyEntry() {
            ConsoleDockPasteboard.copy(ConsoleDockSnapshotFormatter.entryDetailText(entry))
            UIAccessibility.post(notification: .announcement, argument: "Copied log entry")
        }
    }
#endif

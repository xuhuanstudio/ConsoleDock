#if canImport(UIKit)
    import UIKit

    final class ConsoleDockTimelineActionDetailViewController: UIViewController {
        private let execution: ConsoleDock.DebugActionExecution
        private let textView = UITextView()

        init(execution: ConsoleDock.DebugActionExecution) {
            self.execution = execution
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            title = "Action Detail"
            view.backgroundColor = ConsoleDockUIColors.background
            configureNavigationItems()
            configureTextView()
        }

        private func configureNavigationItems() {
            let copyButton = UIBarButtonItem(
                title: "Copy Action",
                style: .plain,
                target: self,
                action: #selector(copyAction)
            )
            copyButton.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.timelineActionDetailCopyButton
            navigationItem.rightBarButtonItem = copyButton
        }

        private func configureTextView() {
            textView.translatesAutoresizingMaskIntoConstraints = false
            textView.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.timelineActionDetailText
            textView.backgroundColor = UIColor(white: 0.04, alpha: 1)
            textView.textColor = ConsoleDockUIColors.primaryText
            textView.font = ConsoleDockFonts.monospace(size: 12, weight: .regular)
            textView.isEditable = false
            textView.alwaysBounceVertical = true
            textView.text = ConsoleDockTimelineBuilder.actionDetailText(execution)
            view.addSubview(textView)

            NSLayoutConstraint.activate([
                textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
                textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
                textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
                textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
            ])
        }

        @objc private func copyAction() {
            ConsoleDockPasteboard.copy(ConsoleDockTimelineBuilder.actionDetailText(execution))
            UIAccessibility.post(notification: .announcement, argument: "Copied action detail")
        }
    }
#endif

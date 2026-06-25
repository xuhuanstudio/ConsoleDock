#if canImport(UIKit)
    import ConsoleDockCore
    import UIKit

    final class ConsoleDockUIController {
        static let shared = ConsoleDockUIController()

        private var overlayWindow: ConsoleDockPassthroughWindow?
        private var dockButton: UIButton?
        private var panelController: ConsoleDockPanelViewController?
        private var lifecycleObservers: [NSObjectProtocol] = []

        private init() {}

        func install() {
            performOnMain { [weak self] in
                guard let self else { return }
                self.installLifecycleObserversIfNeeded()
                self.ensureOverlayWindow()
            }
        }

        func teardown() {
            performOnMain { [weak self] in
                guard let self else { return }
                self.hideConsoleOnMain()
                self.overlayWindow?.isHidden = true
                self.overlayWindow = nil
                self.dockButton = nil
                self.lifecycleObservers.forEach(NotificationCenter.default.removeObserver)
                self.lifecycleObservers.removeAll()
            }
        }

        func showConsole() {
            performOnMain { [weak self] in
                self?.showConsoleOnMain()
            }
        }

        func hideConsole() {
            performOnMain { [weak self] in
                self?.hideConsoleOnMain()
            }
        }

        private func performOnMain(_ work: @escaping () -> Void) {
            if Thread.isMainThread {
                work()
            } else {
                DispatchQueue.main.async(execute: work)
            }
        }

        private func installLifecycleObserversIfNeeded() {
            guard lifecycleObservers.isEmpty else { return }
            let center = NotificationCenter.default
            lifecycleObservers.append(
                center.addObserver(
                    forName: UIApplication.didBecomeActiveNotification,
                    object: nil,
                    queue: .main
                ) { [weak self] _ in
                    self?.ensureOverlayWindow()
                }
            )
            if #available(iOS 13.0, *) {
                lifecycleObservers.append(
                    center.addObserver(
                        forName: UIScene.didActivateNotification,
                        object: nil,
                        queue: .main
                    ) { [weak self] _ in
                        self?.ensureOverlayWindow()
                    }
                )
            }
        }

        private func ensureOverlayWindow() {
            if let overlayWindow {
                overlayWindow.isHidden = false
                return
            }

            guard let window = makeOverlayWindow() else {
                return
            }

            let rootViewController = UIViewController()
            rootViewController.view.backgroundColor = .clear
            window.rootViewController = rootViewController
            window.windowLevel = UIWindow.Level.statusBar + 1
            window.backgroundColor = .clear
            window.isHidden = false

            let button = makeDockButton()
            rootViewController.view.addSubview(button)
            positionDockButton(button, in: rootViewController.view.bounds)

            overlayWindow = window
            dockButton = button
        }

        private func makeOverlayWindow() -> ConsoleDockPassthroughWindow? {
            if #available(iOS 13.0, *) {
                guard let scene = activeWindowScene() else {
                    return nil
                }
                return ConsoleDockPassthroughWindow(windowScene: scene)
            }
            return ConsoleDockPassthroughWindow(frame: UIScreen.main.bounds)
        }

        @available(iOS 13.0, *)
        private func activeWindowScene() -> UIWindowScene? {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }
        }

        private func makeDockButton() -> UIButton {
            let button = UIButton(type: .custom)
            button.frame = CGRect(x: 0, y: 0, width: 54, height: 54)
            button.layer.cornerRadius = 27
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOpacity = 0.25
            button.layer.shadowRadius = 8
            button.layer.shadowOffset = CGSize(width: 0, height: 3)
            button.backgroundColor = UIColor(white: 0.08, alpha: 0.92)
            button.setTitle("CD", for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.dockButton
            button.titleLabel?.font = ConsoleDockFonts.monospace(size: 15, weight: .semibold)
            button.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
            button.addTarget(self, action: #selector(toggleConsole), for: .touchUpInside)
            button.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleDockPan(_:))))
            return button
        }

        private func positionDockButton(_ button: UIButton, in bounds: CGRect) {
            let margin: CGFloat = 18
            let safeBounds = bounds == .zero ? UIScreen.main.bounds : bounds
            button.center = CGPoint(
                x: safeBounds.maxX - margin - button.bounds.width / 2,
                y: safeBounds.maxY - margin - button.bounds.height / 2
            )
        }

        @objc private func toggleConsole() {
            if panelController == nil {
                showConsoleOnMain()
            } else {
                hideConsoleOnMain()
            }
        }

        @objc private func handleDockPan(_ recognizer: UIPanGestureRecognizer) {
            guard let button = dockButton, let container = button.superview else { return }
            let translation = recognizer.translation(in: container)
            recognizer.setTranslation(.zero, in: container)

            let halfWidth = button.bounds.width / 2
            let halfHeight = button.bounds.height / 2
            var center = CGPoint(x: button.center.x + translation.x, y: button.center.y + translation.y)
            center.x = min(max(center.x, halfWidth), container.bounds.width - halfWidth)
            center.y = min(max(center.y, halfHeight), container.bounds.height - halfHeight)
            button.center = center
        }

        private func showConsoleOnMain() {
            ensureOverlayWindow()
            guard panelController == nil, let rootViewController = overlayWindow?.rootViewController else {
                return
            }

            let panel = ConsoleDockPanelViewController()
            panel.onClose = { [weak self] in
                self?.panelController = nil
            }
            let navigationController = UINavigationController(rootViewController: panel)
            navigationController.modalPresentationStyle = .overFullScreen
            navigationController.view.backgroundColor = UIColor.black.withAlphaComponent(0.92)
            panelController = panel
            rootViewController.present(navigationController, animated: true)
        }

        private func hideConsoleOnMain() {
            guard let panelController else { return }
            panelController.dismiss(animated: true)
            self.panelController = nil
        }
    }

    private final class ConsoleDockPassthroughWindow: UIWindow {
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            let hitView = super.hitTest(point, with: event)
            if hitView === self || hitView === rootViewController?.view {
                return nil
            }
            return hitView
        }
    }

    private final class ConsoleDockPanelViewController: UIViewController {
        var onClose: (() -> Void)?

        private let modeControl = UISegmentedControl(items: ["Logs", "Actions"])
        private let logsViewController = ConsoleDockLogsViewController()
        private let actionsViewController = ConsoleDockActionsViewController()
        private var currentViewController: UIViewController?

        override func viewDidLoad() {
            super.viewDidLoad()
            title = "ConsoleDock"
            view.backgroundColor = ConsoleDockUIColors.background
            configureNavigationItems()
            configureModeControl()
            showLogs()
        }

        private func configureNavigationItems() {
            let closeButton = UIBarButtonItem(
                barButtonSystemItem: .done,
                target: self,
                action: #selector(close)
            )
            closeButton.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.closeButton
            navigationItem.leftBarButtonItem = closeButton

            logsViewController.navigationItemsDidChange = { [weak self] items in
                guard self?.modeControl.selectedSegmentIndex == 0 else { return }
                self?.navigationItem.rightBarButtonItems = items
            }
        }

        private func configureModeControl() {
            modeControl.selectedSegmentIndex = 0
            modeControl.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.modeControl
            modeControl.addTarget(self, action: #selector(modeDidChange), for: .valueChanged)
            navigationItem.titleView = modeControl
        }

        @objc private func modeDidChange() {
            if modeControl.selectedSegmentIndex == 0 {
                showLogs()
            } else {
                showActions()
            }
        }

        private func showLogs() {
            modeControl.selectedSegmentIndex = 0
            switchTo(logsViewController)
            logsViewController.activateSearch(in: navigationItem)
        }

        private func showActions() {
            modeControl.selectedSegmentIndex = 1
            switchTo(actionsViewController)
            logsViewController.deactivateSearch()
            navigationItem.searchController = nil
            navigationItem.rightBarButtonItems = []
        }

        private func switchTo(_ nextViewController: UIViewController) {
            guard currentViewController !== nextViewController else { return }
            if let currentViewController {
                currentViewController.willMove(toParent: nil)
                currentViewController.view.removeFromSuperview()
                currentViewController.removeFromParent()
            }

            addChild(nextViewController)
            nextViewController.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(nextViewController.view)
            NSLayoutConstraint.activate([
                nextViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                nextViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                nextViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
                nextViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            nextViewController.didMove(toParent: self)
            currentViewController = nextViewController
        }

        @objc private func close() {
            dismiss(animated: true) { [weak self] in
                self?.onClose?()
            }
        }
    }
#endif

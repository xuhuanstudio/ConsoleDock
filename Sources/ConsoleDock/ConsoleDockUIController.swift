#if canImport(UIKit)
    import ConsoleDockCore
    import UIKit

    final class ConsoleDockUIController {
        static let shared = ConsoleDockUIController()

        private var overlayWindow: ConsoleDockPassthroughWindow?
        private var dockButton: UIButton?
        private var panelController: ConsoleDockPanelViewController?
        private var lifecycleObservers: [NSObjectProtocol] = []
        private var floatingButtonPosition: ConsoleDock.FloatingButtonPosition = .bottomTrailing
        private var showsFloatingButton = true
        private var dockButtonWasDragged = false

        private init() {}

        func configure(floatingButtonPosition: ConsoleDock.FloatingButtonPosition, showsFloatingButton: Bool) {
            performOnMain { [weak self] in
                guard let self else { return }
                self.floatingButtonPosition = floatingButtonPosition
                self.showsFloatingButton = showsFloatingButton
                self.installLifecycleObserversIfNeeded()
                if showsFloatingButton || self.overlayWindow != nil {
                    self.ensureOverlayWindow()
                }
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
                self.floatingButtonPosition = .bottomTrailing
                self.showsFloatingButton = true
                self.dockButtonWasDragged = false
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

        func showFloatingButton() {
            performOnMain { [weak self] in
                guard let self else { return }
                self.showsFloatingButton = true
                self.ensureOverlayWindow()
            }
        }

        func hideFloatingButton() {
            performOnMain { [weak self] in
                guard let self else { return }
                self.showsFloatingButton = false
                self.removeDockButton()
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
                    self?.refreshOverlayWindowForLifecycle()
                }
            )
            if #available(iOS 13.0, *) {
                lifecycleObservers.append(
                    center.addObserver(
                        forName: UIScene.didActivateNotification,
                        object: nil,
                        queue: .main
                    ) { [weak self] _ in
                        self?.refreshOverlayWindowForLifecycle()
                    }
                )
            }
        }

        private func refreshOverlayWindowForLifecycle() {
            if showsFloatingButton || overlayWindow != nil {
                ensureOverlayWindow()
            }
        }

        private func ensureOverlayWindow() {
            if let overlayWindow {
                overlayWindow.isHidden = false
                syncDockButtonVisibility()
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

            overlayWindow = window
            syncDockButtonVisibility()
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

        private func syncDockButtonVisibility() {
            guard let rootView = overlayWindow?.rootViewController?.view else { return }
            if showsFloatingButton {
                let button = dockButton ?? makeDockButton()
                if button.superview == nil {
                    rootView.addSubview(button)
                }
                if dockButton == nil || !dockButtonWasDragged {
                    positionDockButton(button, in: rootView)
                }
                dockButton = button
            } else {
                removeDockButton()
            }
        }

        private func removeDockButton() {
            dockButton?.removeFromSuperview()
            dockButton = nil
            dockButtonWasDragged = false
        }

        private func positionDockButton(_ button: UIButton, in container: UIView) {
            let margin: CGFloat = 18
            let bounds = container.bounds == .zero ? UIScreen.main.bounds : container.bounds
            let insets = container.safeAreaInsets
            let halfWidth = button.bounds.width / 2
            let halfHeight = button.bounds.height / 2
            let leadingX = bounds.minX + insets.left + margin + halfWidth
            let trailingX = bounds.maxX - insets.right - margin - halfWidth
            let topY = bounds.minY + insets.top + margin + halfHeight
            let bottomY = bounds.maxY - insets.bottom - margin - halfHeight

            switch floatingButtonPosition {
            case .topLeading:
                button.center = CGPoint(x: leadingX, y: topY)
            case .topTrailing:
                button.center = CGPoint(x: trailingX, y: topY)
            case .bottomLeading:
                button.center = CGPoint(x: leadingX, y: bottomY)
            case .bottomTrailing:
                button.center = CGPoint(x: trailingX, y: bottomY)
            }
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
            if translation != .zero {
                dockButtonWasDragged = true
            }

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
            configurePanelNavigationBar(navigationController.navigationBar)
            panelController = panel
            rootViewController.present(navigationController, animated: true)
        }

        private func configurePanelNavigationBar(_ navigationBar: UINavigationBar) {
            navigationBar.barStyle = .black
            navigationBar.tintColor = ConsoleDockUIColors.primaryText
            navigationBar.barTintColor = ConsoleDockUIColors.background
            navigationBar.titleTextAttributes = [
                .foregroundColor: ConsoleDockUIColors.primaryText
            ]

            if #available(iOS 13.0, *) {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = ConsoleDockUIColors.background
                appearance.shadowColor = .clear
                appearance.titleTextAttributes = [
                    .foregroundColor: ConsoleDockUIColors.primaryText
                ]
                navigationBar.standardAppearance = appearance
                navigationBar.scrollEdgeAppearance = appearance
                navigationBar.compactAppearance = appearance
            }
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

        private let modeControl = UISegmentedControl(items: ["Logs", "Timeline", "Actions", "Context"])
        private let logsViewController = ConsoleDockLogsViewController()
        private let timelineViewController = ConsoleDockTimelineViewController()
        private let actionsViewController = ConsoleDockActionsViewController()
        private let contextViewController = ConsoleDockContextViewController()
        private let contentView = UIView()
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
            timelineViewController.navigationItemsDidChange = { [weak self] items in
                guard self?.modeControl.selectedSegmentIndex == 1 else { return }
                self?.navigationItem.rightBarButtonItems = items
            }
            contextViewController.navigationItemsDidChange = { [weak self] items in
                guard self?.modeControl.selectedSegmentIndex == 3 else { return }
                self?.navigationItem.rightBarButtonItems = items
            }
        }

        private func configureModeControl() {
            modeControl.selectedSegmentIndex = 0
            modeControl.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.modeControl
            modeControl.addTarget(self, action: #selector(modeDidChange), for: .valueChanged)
            modeControl.translatesAutoresizingMaskIntoConstraints = false
            contentView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(modeControl)
            view.addSubview(contentView)

            NSLayoutConstraint.activate([
                modeControl.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
                modeControl.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
                modeControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),

                contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                contentView.topAnchor.constraint(equalTo: modeControl.bottomAnchor, constant: 10),
                contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }

        @objc private func modeDidChange() {
            switch modeControl.selectedSegmentIndex {
            case 0:
                showLogs()
            case 1:
                showTimeline()
            case 2:
                showActions()
            default:
                showContext()
            }
        }

        private func showLogs() {
            modeControl.selectedSegmentIndex = 0
            switchTo(logsViewController)
            timelineViewController.deactivate()
            actionsViewController.deactivateSearch()
            contextViewController.deactivate()
            logsViewController.activateSearch(in: navigationItem)
        }

        private func showTimeline() {
            modeControl.selectedSegmentIndex = 1
            switchTo(timelineViewController)
            logsViewController.deactivateSearch()
            actionsViewController.deactivateSearch()
            contextViewController.deactivate()
            navigationItem.searchController = nil
            timelineViewController.activate()
        }

        private func showActions() {
            modeControl.selectedSegmentIndex = 2
            switchTo(actionsViewController)
            logsViewController.deactivateSearch()
            timelineViewController.deactivate()
            contextViewController.deactivate()
            actionsViewController.activateSearch(in: navigationItem)
            navigationItem.rightBarButtonItems = []
        }

        private func showContext() {
            modeControl.selectedSegmentIndex = 3
            switchTo(contextViewController)
            logsViewController.deactivateSearch()
            timelineViewController.deactivate()
            actionsViewController.deactivateSearch()
            navigationItem.searchController = nil
            contextViewController.activate()
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
            contentView.addSubview(nextViewController.view)
            NSLayoutConstraint.activate([
                nextViewController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                nextViewController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                nextViewController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
                nextViewController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
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

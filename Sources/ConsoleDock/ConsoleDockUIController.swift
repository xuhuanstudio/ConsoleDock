#if canImport(UIKit)
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

private final class ConsoleDockPanelViewController: UIViewController, UITableViewDataSource {
    var onClose: (() -> Void)?

    private let tableView = UITableView(frame: .zero, style: .plain)
    private var entries: [ConsoleDock.LogEntry] = []
    private var observer: ConsoleDockEntriesObserver?
    private var shareButton: UIBarButtonItem?
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ConsoleDock"
        view.backgroundColor = UIColor(white: 0.06, alpha: 1)
        configureNavigationItems()
        configureTableView()
        observer = ConsoleDockEntriesObserver(deliveryQueue: .main) { [weak self] snapshot in
            self?.apply(snapshot: snapshot)
        }
    }

    deinit {
        observer?.invalidate()
    }

    private func configureNavigationItems() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(close)
        )
        let shareButton = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareSnapshot)
        )
        shareButton.isEnabled = false
        self.shareButton = shareButton

        let clearButton = UIBarButtonItem(
            title: "Clear",
            style: .plain,
            target: self,
            action: #selector(clear)
        )
        navigationItem.rightBarButtonItems = [clearButton, shareButton]
    }

    private func configureTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor(white: 0.06, alpha: 1)
        tableView.separatorColor = UIColor(white: 0.18, alpha: 1)
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 54
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func apply(snapshot: [ConsoleDock.LogEntry]) {
        entries = snapshot
        shareButton?.isEnabled = !entries.isEmpty
        tableView.reloadData()
        guard !entries.isEmpty else { return }
        let indexPath = IndexPath(row: entries.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
    }

    @objc private func clear() {
        ConsoleDock.clear()
        if ConsoleDock.entries.isEmpty {
            apply(snapshot: [])
        }
    }

    @objc private func close() {
        dismiss(animated: true) { [weak self] in
            self?.onClose?()
        }
    }

    @objc private func shareSnapshot() {
        guard !entries.isEmpty else { return }
        let snapshot = ConsoleDockSnapshotFormatter.snapshotText(entries: entries)
        let activityController = UIActivityViewController(activityItems: [snapshot], applicationActivities: nil)
        activityController.popoverPresentationController?.barButtonItem = shareButton
        present(activityController, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        entries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "ConsoleDockEntryCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: reuseIdentifier)
        let entry = entries[indexPath.row]
        cell.backgroundColor = UIColor(white: 0.06, alpha: 1)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = ConsoleDockFonts.monospace(size: 12, weight: .regular)
        cell.textLabel?.textColor = .white
        cell.textLabel?.text = entry.message
        cell.detailTextLabel?.font = ConsoleDockFonts.monospace(size: 10, weight: .regular)
        cell.detailTextLabel?.textColor = color(for: entry.level)
        cell.detailTextLabel?.text = "\(formatter.string(from: entry.timestamp))  \(entry.source.label)  \(entry.level.label)"
        return cell
    }

    private func color(for level: ConsoleDock.LogLevel) -> UIColor {
        switch level {
        case .debug:
            return UIColor(white: 0.65, alpha: 1)
        case .info:
            return UIColor(red: 0.42, green: 0.76, blue: 1.0, alpha: 1)
        case .warning:
            return UIColor(red: 1.0, green: 0.75, blue: 0.25, alpha: 1)
        case .error, .fault:
            return UIColor(red: 1.0, green: 0.36, blue: 0.32, alpha: 1)
        }
    }
}

private enum ConsoleDockFonts {
    static func monospace(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        if #available(iOS 13.0, *) {
            return .monospacedSystemFont(ofSize: size, weight: weight)
        }
        return UIFont(name: "Menlo", size: size) ?? .systemFont(ofSize: size, weight: weight)
    }
}

private extension ConsoleDock.LogLevel {
    var label: String {
        switch self {
        case .debug:
            return "DEBUG"
        case .info:
            return "INFO"
        case .warning:
            return "WARN"
        case .error:
            return "ERROR"
        case .fault:
            return "FAULT"
        }
    }
}

private extension ConsoleDock.LogSource {
    var label: String {
        switch self {
        case .native:
            return "native"
        case .stdout:
            return "stdout"
        case .stderr:
            return "stderr"
        }
    }
}
#endif

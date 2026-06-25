import ConsoleDock
import UIKit

private enum SampleAppLog {
    private static let consoleDockForwarder = ConsoleDock.LogForwarder(category: "sample app logger")

    static func info(_ message: String) {
        let formattedMessage = "[sample app logger] \(message)"
        print(formattedMessage)
        consoleDockForwarder.info(message)
    }
}

private enum SampleAccessibilityIdentifiers {
    static let status = "swift-sample.status"

    static func button(_ title: String) -> String {
        let components =
            title
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        return "swift-sample.\(components.joined(separator: "-"))"
    }
}

final class MainViewController: UIViewController {
    private let statusLabel = UILabel()
    private var counter = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ConsoleDock Sample"
        view.backgroundColor = UIColor(white: 0.96, alpha: 1)
        configureView()
        updateStatus("ConsoleDock started. Tap CD or Show Console.")
    }

    private func configureView() {
        let headingLabel = UILabel()
        headingLabel.text = "ConsoleDock Swift Sample"
        headingLabel.font = .preferredFont(forTextStyle: .title2)
        headingLabel.textColor = .black
        headingLabel.numberOfLines = 0

        let bodyLabel = UILabel()
        bodyLabel.text = "Generate stdout, stderr, and native ConsoleDock logs, then open the in-app console."
        bodyLabel.font = .preferredFont(forTextStyle: .body)
        bodyLabel.textColor = UIColor(white: 0.25, alpha: 1)
        bodyLabel.numberOfLines = 0

        statusLabel.font = .preferredFont(forTextStyle: .footnote)
        statusLabel.textColor = UIColor(white: 0.28, alpha: 1)
        statusLabel.numberOfLines = 0
        statusLabel.accessibilityIdentifier = SampleAccessibilityIdentifiers.status

        let stackView = UIStackView(arrangedSubviews: [
            headingLabel,
            bodyLabel,
            makeButton(title: "Show Console", action: #selector(showConsole)),
            makeButton(title: "Hide Floating Button", action: #selector(hideFloatingButton)),
            makeButton(title: "Show Floating Button", action: #selector(showFloatingButton)),
            makeButton(title: "Log diagnostics", action: #selector(logDiagnostics)),
            makeButton(title: "App logger sink", action: #selector(logAppLoggerSink)),
            makeButton(title: "ConsoleDock.info", action: #selector(logNativeInfo)),
            makeButton(title: "ConsoleDock.error", action: #selector(logNativeError)),
            makeButton(title: "ConsoleDock.fault", action: #selector(logNativeFault)),
            makeButton(title: "print stdout", action: #selector(logPrint)),
            makeButton(title: "printf stdout", action: #selector(logPrintf)),
            makeButton(title: "fprintf stderr", action: #selector(logStderr)),
            makeButton(title: "NSLog", action: #selector(logNSLog)),
            makeButton(title: "Clear ConsoleDock Entries", action: #selector(clearEntries)),
            makeButton(title: "Stop ConsoleDock", action: #selector(stopConsoleDock)),
            makeButton(title: "Start ConsoleDock", action: #selector(startConsoleDock)),
            statusLabel
        ])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 12

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.addSubview(stackView)
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])
    }

    private func makeButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.accessibilityIdentifier = SampleAccessibilityIdentifiers.button(title)
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.backgroundColor = UIColor(white: 1, alpha: 1)
        button.layer.borderColor = UIColor(white: 0.78, alpha: 1).cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func nextMessage(_ prefix: String) -> String {
        counter += 1
        return "\(prefix) #\(counter) token=sample-secret-\(counter)"
    }

    private func updateStatus(_ message: String) {
        let diagnostics = ConsoleDock.diagnostics
        let status = [
            "Running: \(diagnostics.isRunning)",
            "Stored entries: \(diagnostics.entryCount)",
            "stdout: \(diagnostics.capturesStandardOutput)",
            "stderr: \(diagnostics.capturesStandardError)"
        ].joined(separator: "  ")
        statusLabel.text = "\(message)\n\(status)"
    }

    private func updateStatusAfterCapture(_ message: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.updateStatus(message)
        }
    }

    @objc private func showConsole() {
        ConsoleDock.showConsole()
        updateStatus("Requested ConsoleDock panel.")
    }

    @objc private func hideFloatingButton() {
        ConsoleDock.hideFloatingButton()
        updateStatus("Hid ConsoleDock floating button.")
    }

    @objc private func showFloatingButton() {
        ConsoleDock.showFloatingButton()
        updateStatus("Showed ConsoleDock floating button.")
    }

    @objc private func logDiagnostics() {
        let diagnostics = ConsoleDock.diagnostics
        let message = [
            "diagnostics",
            "running=\(diagnostics.isRunning)",
            "entries=\(diagnostics.entryCount)",
            "stdout=\(diagnostics.capturesStandardOutput)",
            "stderr=\(diagnostics.capturesStandardError)",
            "limits=\(diagnostics.maximumEntries)/\(diagnostics.maximumMessageLength)",
            "redacted=\(diagnostics.redactedEntryCount)",
            "truncated=\(diagnostics.truncatedEntryCount)",
            "partial=\(diagnostics.partialEntryCount)"
        ].joined(separator: " ")
        ConsoleDock.info(message)
        updateStatus("Wrote ConsoleDock diagnostics.")
    }

    @objc private func logAppLoggerSink() {
        SampleAppLog.info(nextMessage("app logger sink"))
        fflush(stdout)
        updateStatusAfterCapture("Wrote app logger sink.")
    }

    @objc private func logNativeInfo() {
        let message = nextMessage("native info")
        ConsoleDock.info(message)
        updateStatus("Wrote ConsoleDock.info.")
    }

    @objc private func logNativeError() {
        let message = nextMessage("native error")
        ConsoleDock.error(message)
        updateStatus("Wrote ConsoleDock.error.")
    }

    @objc private func logNativeFault() {
        let message = nextMessage("native fault")
        ConsoleDock.fault(message)
        updateStatus("Wrote ConsoleDock.fault.")
    }

    @objc private func logPrint() {
        print(nextMessage("print stdout"))
        fflush(stdout)
        updateStatusAfterCapture("Wrote print stdout.")
    }

    @objc private func logPrintf() {
        nextMessage("printf stdout").withCString { message in
            SampleLogPrintf(message)
        }
        updateStatusAfterCapture("Wrote printf stdout.")
    }

    @objc private func logStderr() {
        nextMessage("fprintf stderr").withCString { message in
            SampleLogFprintfStderr(message)
        }
        updateStatusAfterCapture("Wrote fprintf stderr.")
    }

    @objc private func logNSLog() {
        NSLog("%@", nextMessage("NSLog output"))
        updateStatusAfterCapture("Wrote NSLog.")
    }

    @objc private func clearEntries() {
        ConsoleDock.clear()
        updateStatus("Cleared ConsoleDock entries.")
    }

    @objc private func stopConsoleDock() {
        ConsoleDock.stop()
        updateStatus("Stopped ConsoleDock.")
    }

    @objc private func startConsoleDock() {
        ConsoleDock.start(configuration: .sample)
        updateStatus("Started ConsoleDock.")
    }
}

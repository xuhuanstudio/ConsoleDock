#if canImport(UIKit)
    import UIKit

    final class ConsoleDockSupportReportViewController: UIViewController {
        private let scrollView = UIScrollView()
        private let contentStackView = UIStackView()
        private let rangeSegmentedControl = UISegmentedControl(
            items: ConsoleDockSupportReportComposerState.TimeRangePreset.allCases.map(\.segmentTitle)
        )
        private let customRangeButton = UIButton(type: .system)
        private let rangeDescriptionLabel = UILabel()
        private let appContextSwitch = UISwitch()
        private let integrationHealthSwitch = UISwitch()
        private let summaryLabel = UILabel()
        private let reportTextView = UITextView()
        private var entriesObserver: ConsoleDockEntriesObserver?
        private var state = ConsoleDockSupportReportComposerState()
        private var report: ConsoleDock.SupportReport?
        private var shareButton: UIBarButtonItem?

        private let customRangeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, HH:mm"
            return formatter
        }()

        override func viewDidLoad() {
            super.viewDidLoad()
            title = "Support Report"
            view.backgroundColor = ConsoleDockUIColors.background
            configureNavigationItems()
            configureLayout()
            configureRangeSection()
            configureContentsSection()
            configureSummarySection()
            configurePreviewSection()
            updateControlsFromState()
            reloadReport(resetPreviewScroll: true)
            entriesObserver = ConsoleDockEntriesObserver(deliveryQueue: .main) { [weak self] _ in
                self?.reloadReport(resetPreviewScroll: false)
            }
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            reloadReport(resetPreviewScroll: false)
        }

        deinit {
            entriesObserver?.invalidate()
        }

        private func configureNavigationItems() {
            let shareButton = UIBarButtonItem(
                barButtonSystemItem: .action,
                target: self,
                action: #selector(shareReport)
            )
            shareButton.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.shareSupportReportButton
            self.shareButton = shareButton

            let copyButton = UIBarButtonItem(
                title: "Copy",
                style: .plain,
                target: self,
                action: #selector(copyReport)
            )
            copyButton.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.copySupportReportButton
            navigationItem.rightBarButtonItems = [shareButton, copyButton]
        }

        private func configureLayout() {
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.alwaysBounceVertical = true
            scrollView.keyboardDismissMode = .onDrag
            scrollView.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.supportReportComposer
            view.addSubview(scrollView)

            contentStackView.translatesAutoresizingMaskIntoConstraints = false
            contentStackView.axis = .vertical
            contentStackView.spacing = 10
            scrollView.addSubview(contentStackView)

            NSLayoutConstraint.activate([
                scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                contentStackView.leadingAnchor.constraint(
                    equalTo: scrollView.contentLayoutGuide.leadingAnchor,
                    constant: 16
                ),
                contentStackView.trailingAnchor.constraint(
                    equalTo: scrollView.contentLayoutGuide.trailingAnchor,
                    constant: -16
                ),
                contentStackView.topAnchor.constraint(
                    equalTo: scrollView.contentLayoutGuide.topAnchor,
                    constant: 14
                ),
                contentStackView.bottomAnchor.constraint(
                    equalTo: scrollView.contentLayoutGuide.bottomAnchor,
                    constant: -16
                ),
                contentStackView.widthAnchor.constraint(
                    equalTo: scrollView.frameLayoutGuide.widthAnchor,
                    constant: -32
                )
            ])
        }

        private func configureRangeSection() {
            contentStackView.addArrangedSubview(makeSectionTitle("Time Range"))

            rangeSegmentedControl.accessibilityIdentifier =
                ConsoleDockAccessibilityIdentifiers.supportReportRangeControl
            ConsoleDockSegmentedControlStyle.applyDarkPanelStyle(to: rangeSegmentedControl)
            rangeSegmentedControl.addTarget(self, action: #selector(rangePresetDidChange), for: .valueChanged)
            rangeSegmentedControl.heightAnchor.constraint(equalToConstant: 34).isActive = true
            contentStackView.addArrangedSubview(rangeSegmentedControl)

            customRangeButton.accessibilityIdentifier =
                ConsoleDockAccessibilityIdentifiers.supportReportCustomRangeButton
            customRangeButton.contentHorizontalAlignment = .leading
            customRangeButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
            customRangeButton.setTitleColor(ConsoleDockUIColors.primaryText, for: .normal)
            customRangeButton.titleLabel?.font = .preferredFont(forTextStyle: .callout)
            customRangeButton.titleLabel?.adjustsFontForContentSizeCategory = true
            customRangeButton.titleLabel?.numberOfLines = 2
            customRangeButton.backgroundColor = ConsoleDockUIColors.panel
            customRangeButton.layer.cornerRadius = 6
            customRangeButton.layer.borderColor = ConsoleDockUIColors.separator.cgColor
            customRangeButton.layer.borderWidth = 1
            customRangeButton.addTarget(self, action: #selector(showCustomRange), for: .touchUpInside)
            customRangeButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
            contentStackView.addArrangedSubview(customRangeButton)

            configureSecondaryLabel(rangeDescriptionLabel)
            rangeDescriptionLabel.accessibilityIdentifier =
                ConsoleDockAccessibilityIdentifiers.supportReportRangeDescription
            contentStackView.addArrangedSubview(rangeDescriptionLabel)
        }

        private func configureContentsSection() {
            contentStackView.setCustomSpacing(18, after: rangeDescriptionLabel)
            contentStackView.addArrangedSubview(makeSectionTitle("Contents"))

            appContextSwitch.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.supportReportAppContextSwitch
            appContextSwitch.accessibilityLabel = "Include App Context"
            appContextSwitch.addTarget(self, action: #selector(contentsDidChange), for: .valueChanged)
            contentStackView.addArrangedSubview(makeSwitchRow(title: "App Context", control: appContextSwitch))

            integrationHealthSwitch.accessibilityIdentifier =
                ConsoleDockAccessibilityIdentifiers.supportReportIntegrationHealthSwitch
            integrationHealthSwitch.accessibilityLabel = "Include ConsoleDock Health"
            integrationHealthSwitch.addTarget(self, action: #selector(contentsDidChange), for: .valueChanged)
            contentStackView.addArrangedSubview(
                makeSwitchRow(title: "ConsoleDock Health", control: integrationHealthSwitch)
            )
        }

        private func configureSummarySection() {
            contentStackView.setCustomSpacing(18, after: integrationHealthSwitch.superview ?? integrationHealthSwitch)
            contentStackView.addArrangedSubview(makeSectionTitle("Summary"))

            summaryLabel.translatesAutoresizingMaskIntoConstraints = false
            summaryLabel.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.supportReportSummary
            summaryLabel.isAccessibilityElement = true
            summaryLabel.numberOfLines = 0
            summaryLabel.font = ConsoleDockFonts.monospace(size: 11, weight: .regular)
            summaryLabel.adjustsFontForContentSizeCategory = true
            summaryLabel.textColor = ConsoleDockUIColors.secondaryText

            let panel = UIView()
            panel.backgroundColor = ConsoleDockUIColors.panel
            panel.layer.cornerRadius = 6
            panel.addSubview(summaryLabel)
            NSLayoutConstraint.activate([
                summaryLabel.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 10),
                summaryLabel.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -10),
                summaryLabel.topAnchor.constraint(equalTo: panel.topAnchor, constant: 10),
                summaryLabel.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -10)
            ])
            contentStackView.addArrangedSubview(panel)
        }

        private func configurePreviewSection() {
            guard let summaryPanel = summaryLabel.superview else { return }
            contentStackView.setCustomSpacing(18, after: summaryPanel)
            contentStackView.addArrangedSubview(makeSectionTitle("Preview"))

            reportTextView.translatesAutoresizingMaskIntoConstraints = false
            reportTextView.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.supportReportPreview
            reportTextView.backgroundColor = UIColor(white: 0.04, alpha: 1)
            reportTextView.textColor = ConsoleDockUIColors.primaryText
            reportTextView.font = ConsoleDockFonts.monospace(size: 11, weight: .regular)
            reportTextView.adjustsFontForContentSizeCategory = true
            reportTextView.isEditable = false
            reportTextView.isSelectable = true
            reportTextView.alwaysBounceVertical = true
            reportTextView.layer.cornerRadius = 6
            reportTextView.layer.borderColor = ConsoleDockUIColors.separator.cgColor
            reportTextView.layer.borderWidth = 1
            reportTextView.heightAnchor.constraint(equalToConstant: 340).isActive = true
            contentStackView.addArrangedSubview(reportTextView)
        }

        private func makeSectionTitle(_ text: String) -> UILabel {
            let label = UILabel()
            label.text = text
            label.font = .preferredFont(forTextStyle: .headline)
            label.adjustsFontForContentSizeCategory = true
            label.textColor = ConsoleDockUIColors.primaryText
            return label
        }

        private func configureSecondaryLabel(_ label: UILabel) {
            label.numberOfLines = 0
            label.font = .preferredFont(forTextStyle: .footnote)
            label.adjustsFontForContentSizeCategory = true
            label.textColor = ConsoleDockUIColors.secondaryText
        }

        private func makeSwitchRow(title: String, control: UISwitch) -> UIView {
            let label = UILabel()
            label.text = title
            label.font = .preferredFont(forTextStyle: .body)
            label.adjustsFontForContentSizeCategory = true
            label.textColor = ConsoleDockUIColors.primaryText

            let row = UIStackView(arrangedSubviews: [label, control])
            row.axis = .horizontal
            row.alignment = .center
            row.distribution = .fill
            row.spacing = 12
            row.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
            return row
        }

        private func updateControlsFromState() {
            rangeSegmentedControl.selectedSegmentIndex = state.selectedPreset?.rawValue ?? UISegmentedControl.noSegment
            appContextSwitch.isOn = state.includesAppContext
            integrationHealthSwitch.isOn = state.includesIntegrationHealth

            let title: String
            if let range = state.customRange {
                title =
                    "Custom: \(customRangeFormatter.string(from: range.from)) to "
                    + customRangeFormatter.string(from: range.to)
            } else {
                title = "Custom Range..."
            }
            customRangeButton.setTitle(title, for: .normal)
            customRangeButton.accessibilityLabel = title
        }

        private func reloadReport(resetPreviewScroll: Bool) {
            let report = ConsoleDock.supportReport(options: state.options)
            self.report = report
            rangeDescriptionLabel.text = report.timeRangeDescription
            rangeDescriptionLabel.accessibilityLabel = "Report range: \(report.timeRangeDescription)"
            summaryLabel.text = state.summaryText(for: report)
            summaryLabel.accessibilityLabel = summaryLabel.text
            reportTextView.text = report.text
            if resetPreviewScroll {
                reportTextView.setContentOffset(.zero, animated: false)
            }
        }

        @objc private func rangePresetDidChange() {
            guard
                let preset = ConsoleDockSupportReportComposerState.TimeRangePreset(
                    rawValue: rangeSegmentedControl.selectedSegmentIndex
                )
            else {
                return
            }
            state.selectPreset(preset)
            updateControlsFromState()
            reloadReport(resetPreviewScroll: true)
        }

        @objc private func showCustomRange() {
            let now = Date()
            let initialRange = state.customRange ?? (now.addingTimeInterval(-10 * 60), now)
            let controller = ConsoleDockSupportReportDateRangeViewController(
                from: initialRange.from,
                to: initialRange.to
            ) { [weak self] from, to in
                guard let self else { return }
                self.state.selectCustomRange(from: from, to: to)
                self.updateControlsFromState()
                self.reloadReport(resetPreviewScroll: true)
            }
            navigationController?.pushViewController(controller, animated: true)
        }

        @objc private func contentsDidChange() {
            state.includesAppContext = appContextSwitch.isOn
            state.includesIntegrationHealth = integrationHealthSwitch.isOn
            reloadReport(resetPreviewScroll: true)
        }

        @objc private func copyReport() {
            reloadReport(resetPreviewScroll: false)
            guard let report else { return }
            ConsoleDockPasteboard.copy(report.text)
            UIAccessibility.post(notification: .announcement, argument: "Copied support report")
        }

        @objc private func shareReport() {
            reloadReport(resetPreviewScroll: false)
            guard let report else { return }

            let activityItems: [Any]
            let temporaryFileURL: URL?
            do {
                let fileURL = try ConsoleDockIssueReportFileExporter.makeTemporarySupportReportFile(
                    reportText: report.text,
                    generatedAt: report.generatedAt
                )
                activityItems = [fileURL]
                temporaryFileURL = fileURL
            } catch {
                ConsoleDock.error("Support report file export failed: \(error)")
                activityItems = [report.text]
                temporaryFileURL = nil
            }

            let activityController = UIActivityViewController(
                activityItems: activityItems,
                applicationActivities: nil
            )
            activityController.completionWithItemsHandler = { _, _, _, _ in
                guard let temporaryFileURL else { return }
                try? FileManager.default.removeItem(at: temporaryFileURL)
            }
            activityController.popoverPresentationController?.barButtonItem = shareButton
            present(activityController, animated: true)
        }
    }

    private final class ConsoleDockSupportReportDateRangeViewController: UIViewController {
        private let scrollView = UIScrollView()
        private let stackView = UIStackView()
        private let fromDatePicker = UIDatePicker()
        private let toDatePicker = UIDatePicker()
        private let onApply: (Date, Date) -> Void

        init(from: Date, to: Date, onApply: @escaping (Date, Date) -> Void) {
            fromDatePicker.date = from
            toDatePicker.date = to
            self.onApply = onApply
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            title = "Custom Range"
            view.backgroundColor = ConsoleDockUIColors.background
            configureNavigationItems()
            configureLayout()
            configurePicker(fromDatePicker, identifier: ConsoleDockAccessibilityIdentifiers.supportReportStartDate)
            configurePicker(toDatePicker, identifier: ConsoleDockAccessibilityIdentifiers.supportReportEndDate)
            addPickerSection(title: "Start", picker: fromDatePicker)
            addPickerSection(title: "End", picker: toDatePicker)
        }

        private func configureNavigationItems() {
            let applyButton = UIBarButtonItem(
                title: "Apply",
                style: .done,
                target: self,
                action: #selector(applyRange)
            )
            applyButton.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.supportReportApplyDateRange
            navigationItem.rightBarButtonItem = applyButton
        }

        private func configureLayout() {
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.alwaysBounceVertical = true
            view.addSubview(scrollView)

            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .vertical
            stackView.spacing = 18
            scrollView.addSubview(stackView)

            NSLayoutConstraint.activate([
                scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                stackView.leadingAnchor.constraint(
                    equalTo: scrollView.contentLayoutGuide.leadingAnchor,
                    constant: 16
                ),
                stackView.trailingAnchor.constraint(
                    equalTo: scrollView.contentLayoutGuide.trailingAnchor,
                    constant: -16
                ),
                stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
                stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
                stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32)
            ])
        }

        private func configurePicker(_ picker: UIDatePicker, identifier: String) {
            picker.datePickerMode = .dateAndTime
            picker.accessibilityIdentifier = identifier
            picker.tintColor = ConsoleDockUIColors.primaryText
            if #available(iOS 13.4, *) {
                picker.preferredDatePickerStyle = .compact
            }
        }

        private func addPickerSection(title: String, picker: UIDatePicker) {
            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.font = .preferredFont(forTextStyle: .headline)
            titleLabel.adjustsFontForContentSizeCategory = true
            titleLabel.textColor = ConsoleDockUIColors.primaryText
            stackView.addArrangedSubview(titleLabel)

            let container = UIView()
            container.backgroundColor = ConsoleDockUIColors.panel
            container.layer.cornerRadius = 6
            picker.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(picker)
            NSLayoutConstraint.activate([
                picker.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
                picker.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
                picker.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
                picker.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
            ])
            stackView.addArrangedSubview(container)
        }

        @objc private func applyRange() {
            onApply(fromDatePicker.date, toDatePicker.date)
            navigationController?.popViewController(animated: true)
        }
    }
#endif

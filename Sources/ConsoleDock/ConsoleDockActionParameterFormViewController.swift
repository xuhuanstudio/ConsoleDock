#if canImport(UIKit)
    import UIKit

    final class ConsoleDockActionParameterFormViewController: UIViewController {
        private enum ParameterBuildResult {
            case success([String: ConsoleDock.DebugActionParameterValue])
            case failure(String)
        }

        private let action: ConsoleDockDebugAction
        private let onRun: ([String: ConsoleDock.DebugActionParameterValue]) -> Void
        private let scrollView = UIScrollView()
        private let stackView = UIStackView()
        private let errorLabel = UILabel()
        private let numberFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return formatter
        }()

        private var stringFields: [String: UITextField] = [:]
        private var numberFields: [String: UITextField] = [:]
        private var boolSwitches: [String: UISwitch] = [:]
        private var choiceControls: [String: UISegmentedControl] = [:]

        init(
            action: ConsoleDockDebugAction,
            onRun: @escaping ([String: ConsoleDock.DebugActionParameterValue]) -> Void
        ) {
            self.action = action
            self.onRun = onRun
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            nil
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            title = action.title
            view.backgroundColor = ConsoleDockUIColors.background
            view.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.actionParameterForm
            configureNavigationItems()
            configureScrollView()
            configureErrorLabel()
            configureParameterRows()
        }

        private func configureNavigationItems() {
            let cancelButton = UIBarButtonItem(
                barButtonSystemItem: .cancel,
                target: self,
                action: #selector(cancel)
            )
            cancelButton.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.actionParameterCancelButton
            navigationItem.leftBarButtonItem = cancelButton

            let runButton = UIBarButtonItem(
                title: "Run Action",
                style: .done,
                target: self,
                action: #selector(runAction)
            )
            runButton.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.actionParameterRunButton
            navigationItem.rightBarButtonItem = runButton
        }

        private func configureScrollView() {
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.alwaysBounceVertical = true
            scrollView.keyboardDismissMode = .interactive
            scrollView.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            view.addSubview(scrollView)

            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .vertical
            stackView.spacing = 14
            stackView.alignment = .fill
            scrollView.addSubview(stackView)

            NSLayoutConstraint.activate([
                scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                stackView.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
                stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
                stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
                stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32)
            ])
        }

        private func configureErrorLabel() {
            errorLabel.translatesAutoresizingMaskIntoConstraints = false
            errorLabel.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.actionParameterError
            errorLabel.font = .preferredFont(forTextStyle: .footnote)
            errorLabel.textColor = ConsoleDockUIColors.level(.error)
            errorLabel.numberOfLines = 0
            errorLabel.isHidden = true
            stackView.addArrangedSubview(errorLabel)
        }

        private func configureParameterRows() {
            for parameter in action.parameters {
                stackView.addArrangedSubview(makeRow(for: parameter))
            }
        }

        private func makeRow(for parameter: ConsoleDock.DebugActionParameter) -> UIView {
            let row = UIStackView()
            row.axis = .vertical
            row.spacing = 6
            row.alignment = .fill
            row.backgroundColor = ConsoleDockUIColors.panel
            row.layer.cornerRadius = 6
            row.layer.borderColor = ConsoleDockUIColors.separator.cgColor
            row.layer.borderWidth = 1
            row.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            row.isLayoutMarginsRelativeArrangement = true

            let titleLabel = UILabel()
            titleLabel.text = parameter.isRequired ? "\(parameter.title) *" : parameter.title
            titleLabel.textColor = ConsoleDockUIColors.primaryText
            titleLabel.font = .preferredFont(forTextStyle: .headline)
            titleLabel.numberOfLines = 0
            row.addArrangedSubview(titleLabel)

            if let detail = parameter.detail {
                let detailLabel = UILabel()
                detailLabel.text = detail
                detailLabel.textColor = ConsoleDockUIColors.secondaryText
                detailLabel.font = .preferredFont(forTextStyle: .footnote)
                detailLabel.numberOfLines = 0
                row.addArrangedSubview(detailLabel)
            }

            row.addArrangedSubview(makeControl(for: parameter))
            return row
        }

        private func makeControl(for parameter: ConsoleDock.DebugActionParameter) -> UIView {
            switch parameter.kind {
            case .string:
                return makeTextField(
                    for: parameter,
                    baseIdentifier: ConsoleDockAccessibilityIdentifiers.actionParameterStringInput,
                    keyboardType: .default,
                    text: defaultString(for: parameter)
                )
            case .number:
                return makeTextField(
                    for: parameter,
                    baseIdentifier: ConsoleDockAccessibilityIdentifiers.actionParameterNumberInput,
                    keyboardType: .decimalPad,
                    text: defaultNumberText(for: parameter)
                )
            case .bool:
                return makeBoolSwitch(for: parameter)
            case .choice(let choices):
                return makeChoiceControl(for: parameter, choices: choices)
            }
        }

        private func makeTextField(
            for parameter: ConsoleDock.DebugActionParameter,
            baseIdentifier: String,
            keyboardType: UIKeyboardType,
            text: String?
        ) -> UITextField {
            let textField = UITextField()
            textField.borderStyle = .roundedRect
            textField.clearButtonMode = .whileEditing
            textField.font = .preferredFont(forTextStyle: .body)
            textField.keyboardType = keyboardType
            textField.text = text
            textField.textColor = .black
            textField.backgroundColor = .white
            textField.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.identifier(
                baseIdentifier,
                parameterID: parameter.id
            )

            switch parameter.kind {
            case .string:
                textField.placeholder = parameter.isRequired ? "Required" : "Optional"
                stringFields[parameter.id] = textField
            case .number:
                textField.placeholder = parameter.isRequired ? "Required number" : "Optional number"
                numberFields[parameter.id] = textField
            default:
                break
            }

            return textField
        }

        private func makeBoolSwitch(for parameter: ConsoleDock.DebugActionParameter) -> UISwitch {
            let toggle = UISwitch()
            toggle.isOn = defaultBool(for: parameter)
            toggle.accessibilityLabel = parameter.title
            toggle.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.identifier(
                ConsoleDockAccessibilityIdentifiers.actionParameterBoolInput,
                parameterID: parameter.id
            )
            boolSwitches[parameter.id] = toggle
            return toggle
        }

        private func makeChoiceControl(
            for parameter: ConsoleDock.DebugActionParameter,
            choices: [ConsoleDock.DebugActionChoice]
        ) -> UISegmentedControl {
            let control = UISegmentedControl(items: choices.map(\.title))
            control.accessibilityLabel = parameter.title
            control.accessibilityIdentifier = ConsoleDockAccessibilityIdentifiers.identifier(
                ConsoleDockAccessibilityIdentifiers.actionParameterChoiceInput,
                parameterID: parameter.id
            )
            control.backgroundColor = UIColor(white: 0.1, alpha: 1)
            control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
            control.setTitleTextAttributes([.foregroundColor: UIColor(white: 0.82, alpha: 1)], for: .normal)

            if case .choice(let defaultID)? = parameter.defaultValue,
                let index = choices.firstIndex(where: { $0.id == defaultID })
            {
                control.selectedSegmentIndex = index
            } else {
                control.selectedSegmentIndex = UISegmentedControl.noSegment
            }

            choiceControls[parameter.id] = control
            return control
        }

        private func defaultString(for parameter: ConsoleDock.DebugActionParameter) -> String? {
            if case .string(let value)? = parameter.defaultValue {
                return value
            }
            return nil
        }

        private func defaultNumberText(for parameter: ConsoleDock.DebugActionParameter) -> String? {
            if case .number(let value)? = parameter.defaultValue {
                return String(value)
            }
            return nil
        }

        private func defaultBool(for parameter: ConsoleDock.DebugActionParameter) -> Bool {
            if case .bool(let value)? = parameter.defaultValue {
                return value
            }
            return false
        }

        @objc private func cancel() {
            navigationController?.popViewController(animated: true)
        }

        @objc private func runAction() {
            switch buildParameterValues() {
            case .success(let values):
                clearValidationError()
                onRun(values)
                navigationController?.popViewController(animated: true)
            case .failure(let message):
                showValidationError(message)
            }
        }

        private func buildParameterValues() -> ParameterBuildResult {
            var values: [String: ConsoleDock.DebugActionParameterValue] = [:]
            var invalidTitles: [String] = []

            for parameter in action.parameters {
                switch parameter.kind {
                case .string:
                    collectStringValue(for: parameter, values: &values, invalidTitles: &invalidTitles)
                case .number:
                    collectNumberValue(for: parameter, values: &values, invalidTitles: &invalidTitles)
                case .bool:
                    if let toggle = boolSwitches[parameter.id] {
                        values[parameter.id] = .bool(toggle.isOn)
                    }
                case .choice(let choices):
                    collectChoiceValue(
                        for: parameter,
                        choices: choices,
                        values: &values,
                        invalidTitles: &invalidTitles
                    )
                }
            }

            if invalidTitles.isEmpty {
                return .success(values)
            }
            return .failure("Missing or invalid: \(invalidTitles.joined(separator: ", "))")
        }

        private func collectStringValue(
            for parameter: ConsoleDock.DebugActionParameter,
            values: inout [String: ConsoleDock.DebugActionParameterValue],
            invalidTitles: inout [String]
        ) {
            let text = stringFields[parameter.id]?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !text.isEmpty else {
                if parameter.isRequired {
                    invalidTitles.append(parameter.title)
                }
                return
            }
            values[parameter.id] = .string(text)
        }

        private func collectNumberValue(
            for parameter: ConsoleDock.DebugActionParameter,
            values: inout [String: ConsoleDock.DebugActionParameterValue],
            invalidTitles: inout [String]
        ) {
            let text = numberFields[parameter.id]?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !text.isEmpty else {
                if parameter.isRequired {
                    invalidTitles.append(parameter.title)
                }
                return
            }

            let value = Double(text) ?? numberFormatter.number(from: text)?.doubleValue
            guard let value, value.isFinite else {
                invalidTitles.append(parameter.title)
                return
            }
            values[parameter.id] = .number(value)
        }

        private func collectChoiceValue(
            for parameter: ConsoleDock.DebugActionParameter,
            choices: [ConsoleDock.DebugActionChoice],
            values: inout [String: ConsoleDock.DebugActionParameterValue],
            invalidTitles: inout [String]
        ) {
            guard let control = choiceControls[parameter.id],
                choices.indices.contains(control.selectedSegmentIndex)
            else {
                if parameter.isRequired {
                    invalidTitles.append(parameter.title)
                }
                return
            }
            values[parameter.id] = .choice(choices[control.selectedSegmentIndex].id)
        }

        private func showValidationError(_ message: String) {
            errorLabel.text = message
            errorLabel.accessibilityLabel = message
            errorLabel.isHidden = false
            UIAccessibility.post(notification: .announcement, argument: message)
        }

        private func clearValidationError() {
            errorLabel.text = nil
            errorLabel.accessibilityLabel = nil
            errorLabel.isHidden = true
        }
    }
#endif

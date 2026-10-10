import KeeperCore
import SnapKit
import TKCoordinator
import TKLocalize
import TKUIKit
import UIKit

public final class DemoSendViewController: UIViewController {
    public var onSent: (() -> Void)?
    public var onCancel: (() -> Void)?

    private let wallet: Wallet
    private var selectedAsset: DemoAsset?

    private let scrollView = TKUIScrollView()
    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        return stack
    }()

    private let headerBadge: UILabel = {
        let label = UILabel()
        label.text = "DEMO SIMULATION"
        label.font = TKTextStyle.label2.font
        label.textColor = .Accent.orange
        label.textAlignment = .center
        return label
    }()

    private let titleDescriptionView: TKTitleDescriptionView = {
        let view = TKTitleDescriptionView(size: .big)
        view.padding = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        return view
    }()

    private let assetSelectorLabel: UILabel = {
        let label = UILabel()
        label.text = "Select Asset"
        label.font = TKTextStyle.label1.font
        label.textColor = .Text.secondary
        return label
    }()

    private let assetSegmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl()
        sc.selectedSegmentTintColor = .Background.contentTint
        return sc
    }()

    private let amountLabel: UILabel = {
        let label = UILabel()
        label.text = "Amount"
        label.font = TKTextStyle.label1.font
        label.textColor = .Text.secondary
        return label
    }()

    private let amountTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "0.0"
        tf.keyboardType = .decimalPad
        tf.font = TKTextStyle.title1.font
        tf.textColor = .Text.primary
        tf.backgroundColor = .Background.content
        tf.layer.cornerRadius = 16
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 10))
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 10))
        tf.leftViewMode = .always
        tf.rightViewMode = .always
        tf.heightAnchor.constraint(equalToConstant: 54).isActive = true
        return tf
    }()

    private let balanceHintLabel: UILabel = {
        let label = UILabel()
        label.font = TKTextStyle.body2.font
        label.textColor = .Text.tertiary
        return label
    }()

    private let recipientLabel: UILabel = {
        let label = UILabel()
        label.text = "Recipient Address"
        label.font = TKTextStyle.label1.font
        label.textColor = .Text.secondary
        return label
    }()

    private let recipientTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Address or name"
        tf.font = TKTextStyle.body2.font
        tf.textColor = .Text.primary
        tf.backgroundColor = .Background.content
        tf.layer.cornerRadius = 16
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 10))
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 10))
        tf.leftViewMode = .always
        tf.rightViewMode = .always
        tf.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return tf
    }()

    private let commentLabel: UILabel = {
        let label = UILabel()
        label.text = "Comment (Optional)"
        label.font = TKTextStyle.label1.font
        label.textColor = .Text.secondary
        return label
    }()

    private let commentTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Comment"
        tf.font = TKTextStyle.body2.font
        tf.textColor = .Text.primary
        tf.backgroundColor = .Background.content
        tf.layer.cornerRadius = 16
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 10))
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 10))
        tf.leftViewMode = .always
        tf.rightViewMode = .always
        tf.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return tf
    }()

    private let feeInfoLabel: UILabel = {
        let label = UILabel()
        label.text = "Estimated Fee: ~0.005 TON"
        label.font = TKTextStyle.body2.font
        label.textColor = .Text.secondary
        label.textAlignment = .center
        return label
    }()

    private let disclaimerLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = TKTextStyle.label2.font
        label.textColor = .Text.secondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let sendButton = TKButton()

    public init(wallet: Wallet) {
        self.wallet = wallet
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadAssets()
    }

    private func setupUI() {
        view.backgroundColor = .Background.page
        title = "Send"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: TKLocales.Actions.cancel,
            style: .plain,
            target: self,
            action: #selector(didTapCancel)
        )

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        let container = UIView()
        scrollView.addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        container.addSubview(contentStackView)
        contentStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-24)
        }

        contentStackView.addArrangedSubview(headerBadge)

        titleDescriptionView.configure(
            model: TKTitleDescriptionView.Model(
                title: "Send",
                bottomDescription: "Transfer tokens to another address."
            )
        )
        contentStackView.addArrangedSubview(titleDescriptionView)

        contentStackView.addArrangedSubview(assetSelectorLabel)
        contentStackView.addArrangedSubview(assetSegmentedControl)
        assetSegmentedControl.addTarget(self, action: #selector(didChangeAsset), for: .valueChanged)

        contentStackView.addArrangedSubview(amountLabel)
        contentStackView.addArrangedSubview(amountTextField)
        contentStackView.addArrangedSubview(balanceHintLabel)

        contentStackView.addArrangedSubview(recipientLabel)
        contentStackView.addArrangedSubview(recipientTextField)

        contentStackView.addArrangedSubview(commentLabel)
        contentStackView.addArrangedSubview(commentTextField)

        contentStackView.addArrangedSubview(feeInfoLabel)

        var buttonConfig = TKButton.Configuration.actionButtonConfiguration(
            category: .primary,
            size: .large
        )
        buttonConfig.content.title = .plainString("Send")
        buttonConfig.action = { [weak self] in
            self?.didTapConfirmSend()
        }
        sendButton.configuration = buttonConfig
        contentStackView.addArrangedSubview(sendButton)
    }

    private func loadAssets() {
        let demoData = DemoWalletRepository.shared.getOrCreateDemoData(walletId: wallet.id)
        assetSegmentedControl.removeAllSegments()
        for (index, asset) in demoData.assets.enumerated() {
            assetSegmentedControl.insertSegment(withTitle: asset.symbol, at: index, animated: false)
        }
        if !demoData.assets.isEmpty {
            assetSegmentedControl.selectedSegmentIndex = 0
            selectedAsset = demoData.assets[0]
            updateBalanceHint()
        }
    }

    @objc private func didChangeAsset() {
        let demoData = DemoWalletRepository.shared.getOrCreateDemoData(walletId: wallet.id)
        let idx = assetSegmentedControl.selectedSegmentIndex
        if idx >= 0 && idx < demoData.assets.count {
            selectedAsset = demoData.assets[idx]
            updateBalanceHint()
        }
    }

    private func updateBalanceHint() {
        guard let selectedAsset else { return }
        balanceHintLabel.text = "Available Demo Balance: \(selectedAsset.amount) \(selectedAsset.symbol)"
    }

    @objc private func didTapCancel() {
        dismiss(animated: true) { [weak self] in
            self?.onCancel?()
        }
    }

    private func didTapConfirmSend() {
        guard let selectedAsset else { return }
        let amountText = amountTextField.text?.replacingOccurrences(of: ",", with: ".") ?? "0"
        guard let amount = Decimal(string: amountText), amount > 0 else {
            showAlert(title: "Invalid Amount", message: "Please enter a valid positive amount.")
            return
        }

        let recipient = recipientTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !recipient.isEmpty else {
            showAlert(title: "Recipient Required", message: "Please specify a destination address.")
            return
        }

        let comment = commentTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            _ = try DemoWalletRepository.shared.simulateSend(
                walletId: wallet.id,
                assetSymbol: selectedAsset.symbol,
                amount: amount,
                recipientAddress: recipient,
                comment: comment
            )

            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            dismiss(animated: true) { [weak self] in
                self?.onSent?()
            }
        } catch {
            showAlert(title: "Simulation Error", message: error.localizedDescription)
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

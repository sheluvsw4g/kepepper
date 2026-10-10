import KeeperCore
import SnapKit
import TKCoordinator
import TKLocalize
import TKUIKit
import UIKit

public final class CreateDemoWalletViewController: UIViewController {
    public var onWalletCreated: (() -> Void)?
    public var onCancel: (() -> Void)?

    private let walletsStore: WalletsStore

    private let scrollView = TKUIScrollView()
    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        return stack
    }()

    private let titleDescriptionView: TKTitleDescriptionView = {
        let view = TKTitleDescriptionView(size: .big)
        view.padding = UIEdgeInsets(top: 24, left: 16, bottom: 8, right: 16)
        return view
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Wallet Name"
        label.font = TKTextStyle.label1.font
        label.textColor = .Text.secondary
        return label
    }()

    private let nameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Wallet Name"
        tf.text = "Wallet 1"
        tf.font = TKTextStyle.body1.font
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

    private let tonLabel: UILabel = {
        let label = UILabel()
        label.text = "Initial TON Balance"
        label.font = TKTextStyle.label1.font
        label.textColor = .Text.secondary
        return label
    }()

    private let tonTextField: UITextField = {
        let tf = UITextField()
        tf.text = "100.0"
        tf.keyboardType = .decimalPad
        tf.font = TKTextStyle.body1.font
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

    private let usdtLabel: UILabel = {
        let label = UILabel()
        label.text = "Initial USD₮ Balance"
        label.font = TKTextStyle.label1.font
        label.textColor = .Text.secondary
        return label
    }()

    private let usdtTextField: UITextField = {
        let tf = UITextField()
        tf.text = "500.0"
        tf.keyboardType = .decimalPad
        tf.font = TKTextStyle.body1.font
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

    private let addressLabel: UILabel = {
        let label = UILabel()
        label.text = "Display Address (Optional)"
        label.font = TKTextStyle.label1.font
        label.textColor = .Text.secondary
        return label
    }()

    private let addressTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Leave empty for auto-generated valid TON address"
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

    private let createButton = TKButton()

    public init(walletsStore: WalletsStore) {
        self.walletsStore = walletsStore
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .Background.page
        title = "New Wallet"

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

        titleDescriptionView.configure(
            model: TKTitleDescriptionView.Model(
                title: "Custom Wallet",
                bottomDescription: "Configure customizable balances, tokens and transaction history for this wallet."
            )
        )
        contentStackView.addArrangedSubview(titleDescriptionView)

        contentStackView.addArrangedSubview(nameLabel)
        contentStackView.addArrangedSubview(nameTextField)

        contentStackView.addArrangedSubview(tonLabel)
        contentStackView.addArrangedSubview(tonTextField)

        contentStackView.addArrangedSubview(usdtLabel)
        contentStackView.addArrangedSubview(usdtTextField)

        contentStackView.addArrangedSubview(addressLabel)
        contentStackView.addArrangedSubview(addressTextField)

        let spacer = UIView()
        spacer.snp.makeConstraints { make in
            make.height.equalTo(16)
        }
        contentStackView.addArrangedSubview(spacer)

        var buttonConfig = TKButton.Configuration.actionButtonConfiguration(
            category: .primary,
            size: .large
        )
        buttonConfig.content.title = .plainString("Create Wallet")
        buttonConfig.action = { [weak self] in
            self?.didTapCreate()
        }
        createButton.configuration = buttonConfig
        contentStackView.addArrangedSubview(createButton)
    }

    @objc private func didTapCancel() {
        dismiss(animated: true) { [weak self] in
            self?.onCancel?()
        }
    }

    private func didTapCreate() {
        let label = (nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? "Wallet"
        let tonVal = Decimal(string: tonTextField.text ?? "100.0") ?? 100.0
        let usdtVal = Decimal(string: usdtTextField.text ?? "500.0") ?? 500.0
        let customAddr = (addressTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }

        let demoWallet = DemoWalletFactory.createDemoWallet(
            label: label,
            initialTonBalance: tonVal,
            initialUsdtBalance: usdtVal,
            customAddress: customAddr
        )

        walletsStore.addWallets([demoWallet]) { [weak self] _ in
            DispatchQueue.main.async {
                self?.dismiss(animated: true) {
                    self?.onWalletCreated?()
                }
            }
        }
    }
}

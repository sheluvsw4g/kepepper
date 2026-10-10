import KeeperCore
import SnapKit
import TKCoordinator
import TKLocalize
import TKUIKit
import UIKit

public final class DemoSwapViewController: UIViewController {
    public var onSwapped: (() -> Void)?
    public var onCancel: (() -> Void)?

    private let wallet: Wallet
    private var assets: [DemoAsset] = []
    private var fromAssetIndex = 0
    private var toAssetIndex = 1

    private let scrollView = TKUIScrollView()
    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        return stack
    }()

    private let headerBadge: UILabel = {
        let label = UILabel()
        label.text = "DEMO SWAP SIMULATION"
        label.font = TKTextStyle.label2.font
        label.textColor = .Accent.orange
        label.textAlignment = .center
        return label
    }()

    private let fromLabel: UILabel = {
        let label = UILabel()
        label.text = "You Pay"
        label.font = TKTextStyle.label1.font
        label.textColor = .Text.secondary
        return label
    }()

    private let fromSegmentedControl = UISegmentedControl()

    private let fromAmountTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "0.0"
        tf.text = "10.0"
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

    private let toLabel: UILabel = {
        let label = UILabel()
        label.text = "You Receive (Estimated)"
        label.font = TKTextStyle.label1.font
        label.textColor = .Text.secondary
        return label
    }()

    private let toSegmentedControl = UISegmentedControl()

    private let toAmountLabel: UILabel = {
        let label = UILabel()
        label.font = TKTextStyle.title1.font
        label.textColor = .Accent.green
        label.backgroundColor = .Background.content
        label.layer.cornerRadius = 16
        label.clipsToBounds = true
        label.textAlignment = .left
        return label
    }()

    private let rateLabel: UILabel = {
        let label = UILabel()
        label.font = TKTextStyle.body2.font
        label.textColor = .Text.secondary
        label.textAlignment = .center
        return label
    }()

    private let disclaimerLabel: UILabel = {
        let label = UILabel()
        label.text = "⚠️ Simulation: Exchanges happen locally without connecting to decentralized exchanges."
        label.font = TKTextStyle.label2.font
        label.textColor = .Accent.orange
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let swapButton = TKButton()

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
        recalculateOutput()
    }

    private func setupUI() {
        view.backgroundColor = .Background.page
        title = "Swap (Demo)"

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

        contentStackView.addArrangedSubview(fromLabel)
        contentStackView.addArrangedSubview(fromSegmentedControl)
        fromSegmentedControl.addTarget(self, action: #selector(didChangeFromAsset), for: .valueChanged)

        contentStackView.addArrangedSubview(fromAmountTextField)
        fromAmountTextField.addTarget(self, action: #selector(amountDidChange), for: .editingChanged)

        contentStackView.addArrangedSubview(toLabel)
        contentStackView.addArrangedSubview(toSegmentedControl)
        toSegmentedControl.addTarget(self, action: #selector(didChangeToAsset), for: .valueChanged)

        toAmountLabel.snp.makeConstraints { make in
            make.height.equalTo(54)
        }
        contentStackView.addArrangedSubview(toAmountLabel)

        contentStackView.addArrangedSubview(rateLabel)
        contentStackView.addArrangedSubview(disclaimerLabel)

        var swapConfig = TKButton.Configuration.actionButtonConfiguration(
            category: .primary,
            size: .large
        )
        swapConfig.content.title = .plainString("Simulate Swap")
        swapConfig.action = { [weak self] in
            self?.didTapSwap()
        }
        swapButton.configuration = swapConfig
        contentStackView.addArrangedSubview(swapButton)
    }

    private func loadAssets() {
        let demoData = DemoWalletRepository.shared.getOrCreateDemoData(walletId: wallet.id)
        self.assets = demoData.assets

        fromSegmentedControl.removeAllSegments()
        toSegmentedControl.removeAllSegments()

        for (idx, asset) in assets.enumerated() {
            fromSegmentedControl.insertSegment(withTitle: asset.symbol, at: idx, animated: false)
            toSegmentedControl.insertSegment(withTitle: asset.symbol, at: idx, animated: false)
        }

        if assets.count > 0 {
            fromSegmentedControl.selectedSegmentIndex = 0
            fromAssetIndex = 0
        }
        if assets.count > 1 {
            toSegmentedControl.selectedSegmentIndex = 1
            toAssetIndex = 1
        } else {
            toSegmentedControl.selectedSegmentIndex = 0
            toAssetIndex = 0
        }
    }

    @objc private func didChangeFromAsset() {
        fromAssetIndex = fromSegmentedControl.selectedSegmentIndex
        recalculateOutput()
    }

    @objc private func didChangeToAsset() {
        toAssetIndex = toSegmentedControl.selectedSegmentIndex
        recalculateOutput()
    }

    @objc private func amountDidChange() {
        recalculateOutput()
    }

    private func recalculateOutput() {
        guard fromAssetIndex < assets.count, toAssetIndex < assets.count else { return }
        let fromAsset = assets[fromAssetIndex]
        let toAsset = assets[toAssetIndex]

        let fromText = fromAmountTextField.text?.replacingOccurrences(of: ",", with: ".") ?? "0"
        let fromAmount = Decimal(string: fromText) ?? 0

        let toPrice = toAsset.priceUsd > 0 ? toAsset.priceUsd : 1
        let toAmount = (fromAmount * fromAsset.priceUsd) / toPrice

        toAmountLabel.text = "   ≈ \(String(format: "%.4f", NSDecimalNumber(decimal: toAmount).doubleValue)) \(toAsset.symbol)"
        rateLabel.text = "1 \(fromAsset.symbol) ≈ \(String(format: "%.4f", NSDecimalNumber(decimal: fromAsset.priceUsd / toPrice).doubleValue)) \(toAsset.symbol)"
    }

    @objc private func didTapCancel() {
        dismiss(animated: true) { [weak self] in
            self?.onCancel?()
        }
    }

    private func didTapSwap() {
        guard fromAssetIndex < assets.count, toAssetIndex < assets.count else { return }
        let fromAsset = assets[fromAssetIndex]
        let toAsset = assets[toAssetIndex]

        if fromAsset.id == toAsset.id {
            showAlert(title: "Same Asset", message: "Please select two different assets to swap.")
            return
        }

        let fromText = fromAmountTextField.text?.replacingOccurrences(of: ",", with: ".") ?? "0"
        guard let fromAmount = Decimal(string: fromText), fromAmount > 0 else {
            showAlert(title: "Invalid Amount", message: "Please enter a positive amount to swap.")
            return
        }

        let toPrice = toAsset.priceUsd > 0 ? toAsset.priceUsd : 1
        let toAmount = (fromAmount * fromAsset.priceUsd) / toPrice

        do {
            _ = try DemoWalletRepository.shared.simulateSwap(
                walletId: wallet.id,
                fromSymbol: fromAsset.symbol,
                toSymbol: toAsset.symbol,
                fromAmount: fromAmount,
                toAmount: toAmount
            )

            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            dismiss(animated: true) { [weak self] in
                self?.onSwapped?()
            }
        } catch {
            showAlert(title: "Swap Error", message: error.localizedDescription)
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

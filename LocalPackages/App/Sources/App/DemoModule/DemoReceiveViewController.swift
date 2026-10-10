import CoreImage.CIFilterBuiltins
import KeeperCore
import SnapKit
import TKCoordinator
import TKLocalize
import TKUIKit
import UIKit

public final class DemoReceiveViewController: UIViewController {
    public var onClose: (() -> Void)?

    private let wallet: Wallet

    private let scrollView = TKUIScrollView()
    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        return stack
    }()

    private let headerBadge: UILabel = {
        let label = UILabel()
        label.text = "DEMO RECEIVE"
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

    private let qrImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .white
        iv.layer.cornerRadius = 20
        iv.clipsToBounds = true
        return iv
    }()

    private let addressContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .Background.content
        view.layer.cornerRadius = 16
        return view
    }()

    private let addressLabel: UILabel = {
        let label = UILabel()
        label.font = TKTextStyle.body2.font
        label.textColor = .Text.primary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let copyButton = TKButton()

    private let disclaimerLabel: UILabel = {
        let label = UILabel()
        label.text = "⚠️ Do not send real funds to this address."
        label.font = TKTextStyle.label2.font
        label.textColor = .Accent.orange
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

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
        loadData()
    }

    private func setupUI() {
        view.backgroundColor = .Background.page
        title = "Receive (Demo)"

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: TKLocales.Actions.done,
            style: .done,
            target: self,
            action: #selector(didTapDone)
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
                title: "Receive Assets",
                bottomDescription: "Share this demonstration address or QR code to test receipt workflows."
            )
        )
        contentStackView.addArrangedSubview(titleDescriptionView)

        qrImageView.snp.makeConstraints { make in
            make.width.height.equalTo(220)
        }
        contentStackView.addArrangedSubview(qrImageView)

        addressContainer.addSubview(addressLabel)
        addressLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
        addressContainer.snp.makeConstraints { make in
            make.width.equalToSuperview()
        }
        contentStackView.addArrangedSubview(addressContainer)

        var copyConfig = TKButton.Configuration.actionButtonConfiguration(
            category: .secondary,
            size: .large
        )
        copyConfig.content.title = .plainString("Copy Demo Address")
        copyConfig.action = { [weak self] in
            self?.didTapCopy()
        }
        copyButton.configuration = copyConfig
        copyButton.snp.makeConstraints { make in
            make.width.equalToSuperview()
        }
        contentStackView.addArrangedSubview(copyButton)

        contentStackView.addArrangedSubview(disclaimerLabel)
    }

    private func loadData() {
        let demoData = DemoWalletRepository.shared.getOrCreateDemoData(walletId: wallet.id)
        let displayAddress = demoData.displayAddress ?? (try? wallet.friendlyAddress.toString()) ?? "UQDemoWalletAddress"
        addressLabel.text = displayAddress

        generateQRCode(from: displayAddress)
    }

    private func generateQRCode(from string: String) {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(Data(string.utf8), forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        if let outputImage = filter.outputImage {
            let transformed = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
            if let cgImage = context.createCGImage(transformed, from: transformed.extent) {
                qrImageView.image = UIImage(cgImage: cgImage)
            }
        }
    }

    @objc private func didTapDone() {
        dismiss(animated: true) { [weak self] in
            self?.onClose?()
        }
    }

    private func didTapCopy() {
        guard let address = addressLabel.text else { return }
        UIPasteboard.general.string = address
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let toast = ToastPresenter()
        toast.show(
            configuration: ToastPresenter.Configuration(
                title: "Demo Address Copied",
                dismissRule: .default
            )
        )
    }
}

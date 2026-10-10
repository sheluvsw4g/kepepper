import KeeperCore
import SnapKit
import TKCoordinator
import TKLocalize
import TKUIKit
import UIKit

public final class DemoManageAssetsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    public var onClose: (() -> Void)?

    private let wallet: Wallet
    private var assets: [DemoAsset] = []

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

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
        title = "Demo Assets & Balance"

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: TKLocales.Actions.done,
            style: .done,
            target: self,
            action: #selector(didTapDone)
        )

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Add Token",
            style: .plain,
            target: self,
            action: #selector(didTapAddAsset)
        )

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        tableView.backgroundColor = .Background.page
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DemoAssetCell")
    }

    private func loadData() {
        let demoData = DemoWalletRepository.shared.getOrCreateDemoData(walletId: wallet.id)
        self.assets = demoData.assets
        tableView.reloadData()
    }

    @objc private func didTapDone() {
        dismiss(animated: true) { [weak self] in
            self?.onClose?()
        }
    }

    @objc private func didTapAddAsset() {
        let alert = UIAlertController(title: "Add Demo Asset", message: "Create a custom token for this wallet", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Token Symbol (e.g. DOGS)"
            tf.text = "DOGS"
        }
        alert.addTextField { tf in
            tf.placeholder = "Token Name (e.g. Dogs)"
            tf.text = "Dogs"
        }
        alert.addTextField { tf in
            tf.placeholder = "Amount (e.g. 100000)"
            tf.keyboardType = .decimalPad
            tf.text = "100000"
        }
        alert.addTextField { tf in
            tf.placeholder = "Price in USD (e.g. 0.0006)"
            tf.keyboardType = .decimalPad
            tf.text = "0.0006"
        }

        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            let symbol = alert.textFields?[0].text?.uppercased() ?? "TOKEN"
            let name = alert.textFields?[1].text ?? symbol
            let amount = Decimal(string: alert.textFields?[2].text ?? "100") ?? 100
            let price = Decimal(string: alert.textFields?[3].text ?? "1.0") ?? 1.0

            let asset = DemoAsset(
                name: name,
                symbol: symbol,
                decimals: 9,
                amount: amount,
                priceUsd: price,
                isTon: false
            )
            DemoWalletRepository.shared.addOrUpdateAsset(walletId: self.wallet.id, asset: asset)
            self.loadData()
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - UITableViewDataSource

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        assets.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "DemoAssetCell")
        cell.backgroundColor = .Background.content
        cell.selectionStyle = .default

        let asset = assets[indexPath.row]
        cell.textLabel?.text = "\(asset.name) (\(asset.symbol))"
        cell.textLabel?.textColor = .Text.primary
        cell.textLabel?.font = TKTextStyle.body1.font

        cell.detailTextLabel?.text = "\(asset.amount) • $\(asset.priceUsd)"
        cell.detailTextLabel?.textColor = .Text.secondary
        cell.detailTextLabel?.font = TKTextStyle.body2.font

        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let asset = assets[indexPath.row]

        let alert = UIAlertController(title: "Edit \(asset.symbol)", message: "Update simulated balance and price", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Amount"
            tf.keyboardType = .decimalPad
            tf.text = "\(asset.amount)"
        }
        alert.addTextField { tf in
            tf.placeholder = "Price in USD"
            tf.keyboardType = .decimalPad
            tf.text = "\(asset.priceUsd)"
        }

        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            let amount = Decimal(string: alert.textFields?[0].text ?? "\(asset.amount)") ?? asset.amount
            let price = Decimal(string: alert.textFields?[1].text ?? "\(asset.priceUsd)") ?? asset.priceUsd

            var updatedAsset = asset
            updatedAsset.amount = amount
            updatedAsset.priceUsd = price

            DemoWalletRepository.shared.addOrUpdateAsset(walletId: self.wallet.id, asset: updatedAsset)
            self.loadData()
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let asset = assets[indexPath.row]
            if asset.isTon {
                let alert = UIAlertController(title: "Cannot delete native TON", message: "You can edit its amount to 0 instead of deleting.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                return
            }
            DemoWalletRepository.shared.removeAsset(walletId: wallet.id, assetId: asset.id)
            loadData()
        }
    }
}

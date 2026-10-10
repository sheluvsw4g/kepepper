import KeeperCore
import SnapKit
import TKCoordinator
import TKLocalize
import TKUIKit
import UIKit

public final class DemoHistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    public var onClose: (() -> Void)?

    private let wallet: Wallet
    private var transactions: [DemoTransaction] = []

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
        title = "Demo History"

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: TKLocales.Actions.done,
            style: .done,
            target: self,
            action: #selector(didTapDone)
        )

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(didTapAddOperation)
        )

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        tableView.backgroundColor = .Background.page
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DemoTxCell")
    }

    private func loadData() {
        let demoData = DemoWalletRepository.shared.getOrCreateDemoData(walletId: wallet.id)
        self.transactions = demoData.transactions
        tableView.reloadData()
    }

    @objc private func didTapDone() {
        dismiss(animated: true) { [weak self] in
            self?.onClose?()
        }
    }

    @objc private func didTapAddOperation() {
        let alert = UIAlertController(title: "Add Demo Operation", message: "Simulate an incoming or outgoing transfer", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Asset (e.g. TON, USD₮, NOT)"
            tf.text = "TON"
        }
        alert.addTextField { tf in
            tf.placeholder = "Amount (e.g. 25.0)"
            tf.keyboardType = .decimalPad
            tf.text = "25.0"
        }
        alert.addTextField { tf in
            tf.placeholder = "Comment"
            tf.text = "Custom simulation event"
        }

        alert.addAction(UIAlertAction(title: "Simulate Receive", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            let symbol = alert.textFields?[0].text ?? "TON"
            let amount = Decimal(string: alert.textFields?[1].text ?? "25.0") ?? 25.0
            let comment = alert.textFields?[2].text

            _ = DemoWalletRepository.shared.simulateReceive(
                walletId: self.wallet.id,
                assetSymbol: symbol,
                amount: amount,
                senderAddress: "UQDemoSender...Simulated",
                comment: comment
            )
            self.loadData()
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - UITableViewDataSource

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        transactions.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "DemoTxCell")
        cell.backgroundColor = .Background.content
        cell.selectionStyle = .none

        let tx = transactions[indexPath.row]
        let typeIcon: String
        let sign: String
        let amountColor: UIColor

        switch tx.type {
        case .send:
            typeIcon = "↗"
            sign = "-"
            amountColor = .Text.primary
        case .receive:
            typeIcon = "↙"
            sign = "+"
            amountColor = .Accent.green
        case .swap:
            typeIcon = "⇄"
            sign = ""
            amountColor = .Accent.blue
        }

        cell.textLabel?.text = "\(typeIcon) \(tx.type.rawValue.capitalized) \(sign)\(tx.amount) \(tx.assetSymbol)"
        cell.textLabel?.textColor = amountColor
        cell.textLabel?.font = TKTextStyle.body1.font

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM, HH:mm"
        let dateString = dateFormatter.string(from: tx.date)

        let commentStr = tx.comment.map { " • \"\($0)\"" } ?? ""
        cell.detailTextLabel?.text = "\(tx.status.rawValue) • \(dateString)\(commentStr)"
        cell.detailTextLabel?.textColor = .Text.secondary
        cell.detailTextLabel?.font = TKTextStyle.body2.font

        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tx = transactions[indexPath.row]
        let details = UIAlertController(
            title: "Simulated Transaction",
            message: "ID: \(tx.id)\nType: \(tx.type.rawValue.uppercased())\nAmount: \(tx.amount) \(tx.assetSymbol)\nFee: \(tx.fee) TON\nStatus: \(tx.status.rawValue) (Not broadcast)\nAddress: \(tx.address)\nComment: \(tx.comment ?? "None")",
            preferredStyle: .alert
        )
        details.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            guard let self else { return }
            DemoWalletRepository.shared.deleteTransaction(walletId: self.wallet.id, transactionId: tx.id)
            self.loadData()
        }))
        details.addAction(UIAlertAction(title: "OK", style: .default))
        present(details, animated: true)
    }

    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let tx = transactions[indexPath.row]
            DemoWalletRepository.shared.deleteTransaction(walletId: wallet.id, transactionId: tx.id)
            loadData()
        }
    }
}

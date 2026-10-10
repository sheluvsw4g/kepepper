import Foundation
import TonSwift

public enum DemoTransactionType: String, Codable, Hashable, Sendable {
    case send
    case receive
    case swap
}

public enum DemoTransactionStatus: String, Codable, Hashable, Sendable {
    case demo = "Demo"
    case simulated = "Simulated"
    case notBroadcast = "Not broadcast"
}

public struct DemoTransaction: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public var type: DemoTransactionType
    public var assetSymbol: String
    public var amount: Decimal
    public var fee: Decimal
    public var date: Date
    public var address: String
    public var status: DemoTransactionStatus
    public var comment: String?

    public init(
        id: String = UUID().uuidString,
        type: DemoTransactionType,
        assetSymbol: String,
        amount: Decimal,
        fee: Decimal = 0.005,
        date: Date = Date(),
        address: String,
        status: DemoTransactionStatus = .simulated,
        comment: String? = nil
    ) {
        self.id = id
        self.type = type
        self.assetSymbol = assetSymbol
        self.amount = amount
        self.fee = fee
        self.date = date
        self.address = address
        self.status = status
        self.comment = comment
    }
}

public struct DemoAsset: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public var name: String
    public var symbol: String
    public var decimals: Int
    public var amount: Decimal
    public var priceUsd: Decimal
    public var iconUrl: String?
    public var isTon: Bool

    public var fiatValue: Decimal {
        amount * priceUsd
    }

    public init(
        id: String = UUID().uuidString,
        name: String,
        symbol: String,
        decimals: Int = 9,
        amount: Decimal,
        priceUsd: Decimal,
        iconUrl: String? = nil,
        isTon: Bool = false
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.decimals = decimals
        self.amount = amount
        self.priceUsd = priceUsd
        self.iconUrl = iconUrl
        self.isTon = isTon
    }
}

public struct DemoWalletData: Codable, Hashable, Sendable {
    public let walletId: String
    public var displayAddress: String?
    public var assets: [DemoAsset]
    public var transactions: [DemoTransaction]

    public var totalFiatBalance: Decimal {
        assets.reduce(Decimal.zero) { $0 + $1.fiatValue }
    }

    public var tonAsset: DemoAsset? {
        assets.first(where: { $0.isTon })
    }

    public init(
        walletId: String,
        displayAddress: String? = nil,
        assets: [DemoAsset] = [],
        transactions: [DemoTransaction] = []
    ) {
        self.walletId = walletId
        self.displayAddress = displayAddress
        self.assets = assets
        self.transactions = transactions
    }

    public static func defaultDemoData(
        walletId: String,
        tonAmount: Decimal = 50.0,
        usdtAmount: Decimal = 250.0,
        displayAddress: String? = nil
    ) -> DemoWalletData {
        let tonAsset = DemoAsset(
            id: "ton_native",
            name: "Toncoin",
            symbol: "TON",
            decimals: 9,
            amount: tonAmount,
            priceUsd: 5.50,
            isTon: true
        )
        let usdtAsset = DemoAsset(
            id: "tether_usdt",
            name: "Tether USD",
            symbol: "USD₮",
            decimals: 6,
            amount: usdtAmount,
            priceUsd: 1.00,
            isTon: false
        )
        let notAsset = DemoAsset(
            id: "notcoin",
            name: "Notcoin",
            symbol: "NOT",
            decimals: 9,
            amount: 15000.0,
            priceUsd: 0.008,
            isTon: false
        )

        let initialTx1 = DemoTransaction(
            type: .receive,
            assetSymbol: "TON",
            amount: tonAmount,
            fee: 0,
            date: Date().addingTimeInterval(-86400 * 2),
            address: "UQBA8lV-J0lK18e5t8f5P4_3uB9G88s8P7A02k_924xk",
            status: .simulated,
            comment: "Deposit"
        )
        let initialTx2 = DemoTransaction(
            type: .receive,
            assetSymbol: "USD₮",
            amount: usdtAmount,
            fee: 0,
            date: Date().addingTimeInterval(-86400 * 1),
            address: "UQC0kM4X1k9vVb3k00A9_dfl4l2m5k9a19m2_38kx92",
            status: .simulated,
            comment: "Transfer"
        )

        return DemoWalletData(
            walletId: walletId,
            displayAddress: displayAddress,
            assets: [tonAsset, usdtAsset, notAsset],
            transactions: [initialTx2, initialTx1]
        )
    }
}

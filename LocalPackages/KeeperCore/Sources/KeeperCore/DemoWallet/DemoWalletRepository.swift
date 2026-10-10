import Foundation

public final class DemoWalletRepository: @unchecked Sendable {
    public static let shared = DemoWalletRepository()

    public static let didUpdateNotification = Notification.Name("DemoWalletRepositoryDidUpdateNotification")

    private let userDefaults: UserDefaults
    private let storageKey = "com.tonkeeper.demo_wallet_storage_v1"
    private let lock = NSRecursiveLock()

    private var inMemoryCache: [String: DemoWalletData] = [:]

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadFromStorage()
    }

    private func loadFromStorage() {
        lock.lock()
        defer { lock.unlock() }

        guard let data = userDefaults.data(forKey: storageKey) else {
            return
        }
        do {
            let decoded = try JSONDecoder().decode([String: DemoWalletData].self, from: data)
            self.inMemoryCache = decoded
        } catch {
            print("DemoWalletRepository: failed to decode cache: \(error)")
        }
    }

    private func persistLocked() {
        do {
            let data = try JSONEncoder().encode(inMemoryCache)
            userDefaults.set(data, forKey: storageKey)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Self.didUpdateNotification, object: nil)
            }
        } catch {
            print("DemoWalletRepository: failed to persist cache: \(error)")
        }
    }

    public func getDemoData(walletId: String) -> DemoWalletData? {
        lock.lock()
        defer { lock.unlock() }
        return inMemoryCache[walletId]
    }

    public func getOrCreateDemoData(
        walletId: String,
        initialTon: Decimal = 50.0,
        initialUsdt: Decimal = 250.0,
        displayAddress: String? = nil
    ) -> DemoWalletData {
        lock.lock()
        defer { lock.unlock() }

        if let existing = inMemoryCache[walletId] {
            return existing
        }

        let newDemo = DemoWalletData.defaultDemoData(
            walletId: walletId,
            tonAmount: initialTon,
            usdtAmount: initialUsdt,
            displayAddress: displayAddress
        )
        inMemoryCache[walletId] = newDemo
        persistLocked()
        return newDemo
    }

    public func saveDemoData(_ data: DemoWalletData) {
        lock.lock()
        defer { lock.unlock() }

        inMemoryCache[data.walletId] = data
        persistLocked()
    }

    public func deleteDemoData(walletId: String) {
        lock.lock()
        defer { lock.unlock() }

        inMemoryCache.removeValue(forKey: walletId)
        persistLocked()
    }

    public func updateTonBalance(walletId: String, newAmount: Decimal) {
        lock.lock()
        defer { lock.unlock() }

        guard var data = inMemoryCache[walletId] else { return }
        if let idx = data.assets.firstIndex(where: { $0.isTon }) {
            data.assets[idx].amount = newAmount
        } else {
            let tonAsset = DemoAsset(
                id: "ton_native",
                name: "Toncoin",
                symbol: "TON",
                decimals: 9,
                amount: newAmount,
                priceUsd: 5.50,
                isTon: true
            )
            data.assets.insert(tonAsset, at: 0)
        }
        inMemoryCache[walletId] = data
        persistLocked()
    }

    public func addOrUpdateAsset(walletId: String, asset: DemoAsset) {
        lock.lock()
        defer { lock.unlock() }

        guard var data = inMemoryCache[walletId] else { return }
        if let idx = data.assets.firstIndex(where: { $0.id == asset.id || ($0.symbol.lowercased() == asset.symbol.lowercased() && $0.isTon == asset.isTon) }) {
            data.assets[idx] = asset
        } else {
            data.assets.append(asset)
        }
        inMemoryCache[walletId] = data
        persistLocked()
    }

    public func removeAsset(walletId: String, assetId: String) {
        lock.lock()
        defer { lock.unlock() }

        guard var data = inMemoryCache[walletId] else { return }
        data.assets.removeAll(where: { $0.id == assetId })
        inMemoryCache[walletId] = data
        persistLocked()
    }

    public func addTransaction(walletId: String, transaction: DemoTransaction) {
        lock.lock()
        defer { lock.unlock() }

        guard var data = inMemoryCache[walletId] else { return }
        data.transactions.insert(transaction, at: 0)
        inMemoryCache[walletId] = data
        persistLocked()
    }

    public func deleteTransaction(walletId: String, transactionId: String) {
        lock.lock()
        defer { lock.unlock() }

        guard var data = inMemoryCache[walletId] else { return }
        data.transactions.removeAll(where: { $0.id == transactionId })
        inMemoryCache[walletId] = data
        persistLocked()
    }

    public func simulateSend(
        walletId: String,
        assetSymbol: String,
        amount: Decimal,
        recipientAddress: String,
        comment: String?
    ) throws -> DemoTransaction {
        lock.lock()
        defer { lock.unlock() }

        guard var data = inMemoryCache[walletId] else {
            throw DemoError.walletNotFound
        }

        guard let assetIndex = data.assets.firstIndex(where: { $0.symbol.lowercased() == assetSymbol.lowercased() }) else {
            throw DemoError.assetNotFound
        }

        let currentAmount = data.assets[assetIndex].amount
        if currentAmount < amount {
            throw DemoError.insufficientFunds
        }

        data.assets[assetIndex].amount = currentAmount - amount

        let tx = DemoTransaction(
            type: .send,
            assetSymbol: assetSymbol,
            amount: amount,
            fee: 0.005,
            date: Date(),
            address: recipientAddress,
            status: .simulated,
            comment: comment
        )
        data.transactions.insert(tx, at: 0)

        inMemoryCache[walletId] = data
        persistLocked()

        return tx
    }

    public func simulateReceive(
        walletId: String,
        assetSymbol: String,
        amount: Decimal,
        senderAddress: String,
        comment: String?
    ) -> DemoTransaction {
        lock.lock()
        defer { lock.unlock() }

        var data = inMemoryCache[walletId] ?? DemoWalletData.defaultDemoData(walletId: walletId)

        if let assetIndex = data.assets.firstIndex(where: { $0.symbol.lowercased() == assetSymbol.lowercased() }) {
            data.assets[assetIndex].amount += amount
        } else {
            let newAsset = DemoAsset(
                name: assetSymbol,
                symbol: assetSymbol,
                amount: amount,
                priceUsd: 1.0,
                isTon: assetSymbol.uppercased() == "TON"
            )
            data.assets.append(newAsset)
        }

        let tx = DemoTransaction(
            type: .receive,
            assetSymbol: assetSymbol,
            amount: amount,
            fee: 0,
            date: Date(),
            address: senderAddress,
            status: .simulated,
            comment: comment
        )
        data.transactions.insert(tx, at: 0)

        inMemoryCache[walletId] = data
        persistLocked()

        return tx
    }

    public func simulateSwap(
        walletId: String,
        fromSymbol: String,
        toSymbol: String,
        fromAmount: Decimal,
        toAmount: Decimal
    ) throws -> DemoTransaction {
        lock.lock()
        defer { lock.unlock() }

        guard var data = inMemoryCache[walletId] else {
            throw DemoError.walletNotFound
        }

        guard let fromIndex = data.assets.firstIndex(where: { $0.symbol.lowercased() == fromSymbol.lowercased() }) else {
            throw DemoError.assetNotFound
        }

        if data.assets[fromIndex].amount < fromAmount {
            throw DemoError.insufficientFunds
        }

        data.assets[fromIndex].amount -= fromAmount

        if let toIndex = data.assets.firstIndex(where: { $0.symbol.lowercased() == toSymbol.lowercased() }) {
            data.assets[toIndex].amount += toAmount
        } else {
            let newAsset = DemoAsset(
                name: toSymbol,
                symbol: toSymbol,
                amount: toAmount,
                priceUsd: (fromAmount * data.assets[fromIndex].priceUsd) / (toAmount > 0 ? toAmount : 1),
                isTon: toSymbol.uppercased() == "TON"
            )
            data.assets.append(newAsset)
        }

        let tx = DemoTransaction(
            type: .swap,
            assetSymbol: "\(fromSymbol) → \(toSymbol)",
            amount: toAmount,
            fee: 0.01,
            date: Date(),
            address: "Demo DEX Simulation",
            status: .simulated,
            comment: "Swapped \(fromAmount) \(fromSymbol) for \(toAmount) \(toSymbol)"
        )
        data.transactions.insert(tx, at: 0)

        inMemoryCache[walletId] = data
        persistLocked()

        return tx
    }

    public enum DemoError: LocalizedError {
        case walletNotFound
        case assetNotFound
        case insufficientFunds

        public var errorDescription: String? {
            switch self {
            case .walletNotFound: return "Demo wallet was not found."
            case .assetNotFound: return "Demo asset was not found."
            case .insufficientFunds: return "Insufficient demo funds for this operation."
            }
        }
    }
}

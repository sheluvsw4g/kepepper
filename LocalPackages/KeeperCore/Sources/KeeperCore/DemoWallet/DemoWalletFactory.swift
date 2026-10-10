import Foundation
import TonSwift

public struct DemoWalletFactory {
    public static func createDemoWallet(
        label: String = "Wallet",
        initialTonBalance: Decimal = 100.0,
        initialUsdtBalance: Decimal = 500.0,
        customAddress: String? = nil,
        tintColor: WalletTintColor? = nil
    ) -> Wallet {
        var randomBytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, 32, &randomBytes)
        let publicKey = TonSwift.PublicKey(data: Data(randomBytes))

        let identity = WalletIdentity(
            network: .mainnet,
            kind: .Regular(publicKey, .v4R2)
        )

        let walletId = (try? identity.identifier().toRaw()) ?? UUID().uuidString

        let selectedTintColor = tintColor ?? WalletTintColor.allCases.randomElement() ?? .accentBlue
        let metaData = WalletMetaData(
            label: label.isEmpty ? "Wallet" : label,
            tintColor: selectedTintColor,
            icon: .icon(.wallet)
        )

        let setupSettings = WalletSetupSettings(
            backupDate: Date(),
            isSetupFinished: true
        )

        let wallet = Wallet(
            id: walletId,
            identity: identity,
            metaData: metaData,
            setupSettings: setupSettings,
            batterySettings: BatterySettings(),
            type: .fake
        )

        // Initialize isolated demo storage for this wallet
        let effectiveDisplayAddress = customAddress?.trimmingCharacters(in: .whitespacesAndNewlines)
        _ = DemoWalletRepository.shared.getOrCreateDemoData(
            walletId: wallet.id,
            initialTon: initialTonBalance,
            initialUsdt: initialUsdtBalance,
            displayAddress: (effectiveDisplayAddress?.isEmpty == false) ? effectiveDisplayAddress : (try? wallet.friendlyAddress.toString())
        )

        return wallet
    }
}

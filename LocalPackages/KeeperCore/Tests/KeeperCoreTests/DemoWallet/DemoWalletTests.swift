import Foundation
@testable import KeeperCore
import TonSwift
import XCTest

final class DemoWalletTests: XCTestCase {
    
    private var testWalletId: String!
    private var repository: DemoWalletRepository!
    
    override func setUp() {
        super.setUp()
        testWalletId = "test_wallet_" + UUID().uuidString
        repository = DemoWalletRepository.shared
        repository.deleteDemoData(walletId: testWalletId)
    }
    
    override func tearDown() {
        if let testWalletId = testWalletId {
            repository.deleteDemoData(walletId: testWalletId)
        }
        super.tearDown()
    }
    
    // MARK: - Wallet Model & WalletType Tests
    
    func test_walletTypeDefaultsToOriginal() {
        let type = WalletType.original
        XCTAssertEqual(type.rawValue, "original")
        XCTAssertFalse(type == .fake)
    }
    
    func test_walletTypeFake() {
        let type = WalletType.fake
        XCTAssertEqual(type.rawValue, "fake")
        XCTAssertTrue(type == .fake)
    }
    
    // MARK: - Factory & Initialization Tests
    
    func test_factoryCreatesDemoWalletWithInitialState() {
        let wallet = DemoWalletFactory.createDemoWallet(
            label: "Main Wallet",
            initialTonBalance: 250.0,
            initialUsdtBalance: 1500.0,
            customAddress: nil
        )
        
        XCTAssertTrue(wallet.isDemo)
        XCTAssertEqual(wallet.type, .fake)
        XCTAssertEqual(wallet.label, "Main Wallet")
        let demoData = repository.getDemoData(walletId: wallet.id)
        XCTAssertNotNil(demoData)
        XCTAssertEqual(demoData?.tonAsset?.amount, 250.0)
        XCTAssertFalse(demoData?.displayAddress?.isEmpty ?? true)
        XCTAssertFalse(demoData?.assets.isEmpty ?? true)
        XCTAssertFalse(demoData?.transactions.isEmpty ?? true)
        
        // Clean up
        repository.deleteDemoData(walletId: wallet.id)
    }
    
    // MARK: - Asset Management Tests
    
    func test_assetManagementAddUpdateDelete() {
        let data = repository.getOrCreateDemoData(
            walletId: testWalletId,
            initialTon: 100.0,
            initialUsdt: 500.0
        )
        
        XCTAssertEqual(data.tonAsset?.amount, 100.0)
        
        // Add new asset
        let newAsset = DemoAsset(
            id: "notcoin",
            name: "Notcoin",
            symbol: "NOT",
            decimals: 9,
            amount: 1_000_000,
            priceUsd: 0.008
        )
        repository.addOrUpdateAsset(walletId: testWalletId, asset: newAsset)
        
        var loaded = repository.getDemoData(walletId: testWalletId)
        XCTAssertNotNil(loaded)
        XCTAssertTrue(loaded?.assets.contains(where: { $0.symbol == "NOT" }) ?? false)
        
        // Update balance
        var updatedAsset = newAsset
        updatedAsset.amount = 2_000_000
        repository.addOrUpdateAsset(walletId: testWalletId, asset: updatedAsset)
        loaded = repository.getDemoData(walletId: testWalletId)
        XCTAssertEqual(loaded?.assets.first(where: { $0.symbol == "NOT" })?.amount, 2_000_000)
        
        // Delete asset
        repository.removeAsset(walletId: testWalletId, assetId: "notcoin")
        let deleted = repository.getDemoData(walletId: testWalletId)
        XCTAssertFalse(deleted?.assets.contains(where: { $0.symbol == "NOT" }) ?? true)
    }
    
    // MARK: - Simulate Send Tests
    
    func test_simulateSendSuccess() {
        _ = repository.getOrCreateDemoData(
            walletId: testWalletId,
            initialTon: 100.0,
            initialUsdt: 500.0
        )
        
        let recipient = "UQBA8lV-J0lK18e5t8f5P4_3uB9G88s8P7A02k_924xk"
        do {
            let tx = try repository.simulateSend(
                walletId: testWalletId,
                assetSymbol: "TON",
                amount: 25.0,
                recipientAddress: recipient,
                comment: "Payment"
            )
            
            XCTAssertEqual(tx.type, .send)
            XCTAssertEqual(tx.assetSymbol, "TON")
            XCTAssertEqual(tx.amount, 25.0)
            XCTAssertEqual(tx.status, .simulated)
            XCTAssertEqual(tx.address, recipient)
            XCTAssertEqual(tx.comment, "Payment")
            
            // Verify balance decreased
            let updated = repository.getDemoData(walletId: testWalletId)!
            XCTAssertEqual(updated.tonAsset?.amount, 75.0)
            XCTAssertEqual(updated.transactions.first?.type, .send)
        } catch {
            XCTFail("Send failed with error: \(error)")
        }
    }
    
    func test_simulateSendInsufficientBalance() {
        _ = repository.getOrCreateDemoData(
            walletId: testWalletId,
            initialTon: 10.0,
            initialUsdt: 50.0
        )
        
        XCTAssertThrowsError(
            try repository.simulateSend(
                walletId: testWalletId,
                assetSymbol: "TON",
                amount: 50.0,
                recipientAddress: "UQBA8lV-J0lK18e5t8f5P4_3uB9G88s8P7A02k_924xk",
                comment: nil
            )
        )
    }
    
    // MARK: - Simulate Receive Tests
    
    func test_simulateReceive() {
        _ = repository.getOrCreateDemoData(
            walletId: testWalletId,
            initialTon: 50.0,
            initialUsdt: 100.0
        )
        
        let tx = repository.simulateReceive(
            walletId: testWalletId,
            assetSymbol: "USD₮",
            amount: 250.0,
            senderAddress: "UQC0kM4X1k9vVb3k00A9_dfl4l2m5k9a19m2_38kx92",
            comment: "Bonus"
        )
        
        XCTAssertEqual(tx.type, .receive)
        XCTAssertEqual(tx.assetSymbol, "USD₮")
        XCTAssertEqual(tx.amount, 250.0)
        XCTAssertEqual(tx.status, .simulated)
        
        let updated = repository.getDemoData(walletId: testWalletId)!
        let usdt = updated.assets.first(where: { $0.symbol == "USD₮" })
        XCTAssertEqual(usdt?.amount, 350.0)
        XCTAssertEqual(updated.transactions.first?.id, tx.id)
    }
    
    // MARK: - Simulate Swap Tests
    
    func test_simulateSwap() {
        _ = repository.getOrCreateDemoData(
            walletId: testWalletId,
            initialTon: 100.0,
            initialUsdt: 500.0
        )
        
        do {
            let tx = try repository.simulateSwap(
                walletId: testWalletId,
                fromSymbol: "TON",
                toSymbol: "USD₮",
                fromAmount: 10.0,
                toAmount: 52.0
            )
            
            XCTAssertEqual(tx.type, .swap)
            XCTAssertEqual(tx.status, .simulated)
            
            let updated = repository.getDemoData(walletId: testWalletId)!
            XCTAssertEqual(updated.tonAsset?.amount, 90.0)
            let usdt = updated.assets.first(where: { $0.symbol == "USD₮" })
            XCTAssertEqual(usdt?.amount, 552.0)
        } catch {
            XCTFail("Swap failed with error: \(error)")
        }
    }
    
    // MARK: - Multi-Wallet Isolation Tests
    
    func test_demoWalletIsolation() {
        let walletId1 = "wallet_isolation_1"
        let walletId2 = "wallet_isolation_2"
        
        defer {
            repository.deleteDemoData(walletId: walletId1)
            repository.deleteDemoData(walletId: walletId2)
        }
        
        _ = repository.getOrCreateDemoData(walletId: walletId1, initialTon: 100, initialUsdt: 0)
        _ = repository.getOrCreateDemoData(walletId: walletId2, initialTon: 500, initialUsdt: 0)
        
        // Modify wallet 1
        _ = try? repository.simulateSend(
            walletId: walletId1,
            assetSymbol: "TON",
            amount: 50,
            recipientAddress: "UQRecipient",
            comment: nil
        )
        
        let data1 = repository.getDemoData(walletId: walletId1)!
        let data2 = repository.getDemoData(walletId: walletId2)!
        
        // Wallet 1 should have deducted
        XCTAssertEqual(data1.tonAsset?.amount, 50.0)
        // Wallet 2 should remain completely untouched
        XCTAssertEqual(data2.tonAsset?.amount, 500.0)
        XCTAssertFalse(data2.transactions.contains(where: { $0.address == "UQRecipient" }))
    }
}

import Foundation

public enum WalletType: String, Codable, Hashable, Sendable {
    case original
    case fake

    public var isDemo: Bool {
        self == .fake
    }
}

// Alias for convenience
public typealias WalletMode = WalletType

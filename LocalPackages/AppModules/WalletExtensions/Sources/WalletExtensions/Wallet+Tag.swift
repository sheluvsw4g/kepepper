import KeeperCore
import TKLocalize
import TKUIKit
import UIKit

public extension WalletContractVersion {
    var tag: String? {
        switch self {
        case .v5Beta:
            "W5 BETA"
        case .v5R1:
            "W5"
        default: nil
        }
    }
}

public extension Wallet {
    var kindTag: String? {
        if isDemo {
            return "DEMO"
        }
        switch kind {
        case .regular:
            switch network {
            case .testnet: return "TESTNET"
            case .mainnet: return nil
            }
        case .lockup:
            return nil
        case .watchonly:
            return TKLocales.WalletTags.watchOnly
        case .signer:
            return "SIGNER"
        case .ledger:
            return "LEDGER"
        case .keystone:
            return "KEYSTONE"
        }
    }

    var revisionTag: String? {
        try? contractVersion.tag
    }
}

public extension Wallet {
    func copyToastConfiguration() -> ToastPresenter.Configuration {
        let backgroundColor: UIColor
        let foregroundColor: UIColor

        switch kind {
        case .regular:
            if network == .mainnet {
                backgroundColor = .Background.contentTint
                foregroundColor = .Text.primary
            } else {
                backgroundColor = .Accent.orange
                foregroundColor = .Text.primary
            }
        case .lockup:
            backgroundColor = .Background.contentTint
            foregroundColor = .Text.primary
        case .watchonly:
            backgroundColor = .Accent.orange
            foregroundColor = .Text.primary
        default:
            backgroundColor = .Background.contentTint
            foregroundColor = .Text.primary
        }

        return ToastPresenter.Configuration(
            title: TKLocales.Toast.copied,
            icon: .TKUIKit.Icons.Size16.checkmarkCircle,
            iconTintColor: .Accent.green,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            dismissRule: .default
        )
    }

    func listTagConfigurations() -> [TKTagView.Configuration] {
        if isDemo {
            return [listTagConfiguration()].compactMap { $0 }
        }
        return [revisionTagConfiguration(), listTagConfiguration()].compactMap { $0 }
    }

    func balanceTagSwiftUIConfigurations() -> [TKTagSwiftUIViewConfig] {
        if isDemo {
            return [balanceKindTagSwiftUIConfiguration()].compactMap { $0 }
        }
        return [revisionTagSwiftUIConfiguration(), balanceKindTagSwiftUIConfiguration()].compactMap { $0 }
    }

    func listTagSwiftUIConfigurations() -> [TKTagSwiftUIViewConfig] {
        if isDemo {
            return [listTagSwiftUIConfiguration()].compactMap { $0 }
        }
        return [revisionTagSwiftUIConfiguration(), listTagSwiftUIConfiguration()].compactMap { $0 }
    }

    func balanceKindTagSwiftUIConfiguration() -> TKTagSwiftUIViewConfig? {
        if isDemo {
            return .accentTag(text: "DEMO", accent: .accentOrange)
        }
        let accent: TKColor? = {
            switch kind {
            case .regular:
                network == .mainnet ? nil : .accentOrange
            case .lockup:
                nil
            case .watchonly:
                .accentOrange
            case .signer:
                .accentPurple
            case .ledger:
                .accentGreen
            case .keystone:
                .accentPurple
            }
        }()
        guard let kindTag, let accent else { return nil }
        return .accentTag(text: kindTag, accent: accent)
    }

    func revisionTagSwiftUIConfiguration() -> TKTagSwiftUIViewConfig? {
        guard let revisionTag else { return nil }
        return .accentTag(text: revisionTag, accent: .accentGreen)
    }

    func listTagSwiftUIConfiguration() -> TKTagSwiftUIViewConfig? {
        if isDemo {
            return .accentTag(text: "DEMO", accent: .accentOrange)
        }
        guard let tag = kindTag else { return nil }
        return .tag(text: tag)
    }

    func revisionTagConfiguration() -> TKTagView.Configuration? {
        guard let revisionTag else { return nil }
        return .accentTag(text: revisionTag, color: .Accent.green)
    }

    func receiveTagSwiftUIConfiguration() -> TKTagSwiftUIViewConfig? {
        if isDemo {
            return TKTagSwiftUIViewConfig(text: "DEMO", style: .custom(textColor: .constantBlack, backgroundColor: .accentOrange, borderColor: .clear))
        }
        guard let tag = kindTag else { return nil }

        let style: TKTagSwiftUIViewConfig.Style
        switch kind {
        case .regular:
            if network == .mainnet {
                return nil
            }
            style = .custom(textColor: .constantBlack, backgroundColor: .accentOrange, borderColor: .clear)
        case .lockup:
            return nil
        case .watchonly:
            style = .custom(textColor: .constantBlack, backgroundColor: .accentOrange, borderColor: .clear)
        case .signer, .ledger, .keystone:
            style = .accent(.accentPurple)
        }

        return TKTagSwiftUIViewConfig(text: tag, style: style)
    }

    func listTagConfiguration() -> TKTagView.Configuration? {
        if isDemo {
            return TKTagView.Configuration.accentTag(text: "DEMO", color: .Accent.orange)
        }
        guard let tag = kindTag else { return nil }
        return TKTagView.Configuration.tag(text: tag)
    }
}

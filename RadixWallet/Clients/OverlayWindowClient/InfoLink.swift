import Foundation

// MARK: - OverlayWindowClient.InfoLink
extension OverlayWindowClient {
	public enum InfoLink: Equatable, Sendable {
		case info(InfoItem)
		case glossary(GlossaryItem)

		public enum InfoItem: String, Sendable {
			case radixConnect
			case linkingNewAccount
		}

		public enum GlossaryItem: String, Sendable {
			case radixnetwork
			case radquest
			case tokens
			case nfts
			case web3
			case accounts
			case personas
			case radixwallet
			case dapps
			case transactions
			case transactionfee
			case xrd
			case badges
			case transfers
			case dex
			case guarantees
			case networkstaking
			case validators
			case radixconnector
			case connectbutton
			case dashboard
			case bridging
		}
	}
}

extension OverlayWindowClient.InfoLink {
	public enum AnchorType: String, Sendable {
		case info = "infoAnchor"
		case glossary = "glossaryAnchor"
	}

	public init?(url: URL) {
		guard url.scheme == nil, url.host == nil, url.pathComponents.isEmpty, let query = url.query() else {
			return nil
		}

		let parts = query.split(separator: "=")
		guard parts.count == 2, let type = AnchorType(rawValue: String(parts[0])) else { return nil }
		switch type {
		case .info:
			guard let item = InfoItem(rawValue: String(parts[1])) else { return nil }
			self = .info(item)
		case .glossary:
			guard let item = GlossaryItem(rawValue: String(parts[1])) else { return nil }
			self = .glossary(item)
		}
	}

	var string: String {
		switch self {
		case let .info(item):
			item.string
		case let .glossary(item):
			item.string
		}
	}
}

extension OverlayWindowClient.InfoLink.InfoItem {
	var string: String {
		switch self {
		case .radixConnect:
			fatalError()
		case .linkingNewAccount:
			fatalError()
		}
	}
}

extension OverlayWindowClient.InfoLink.GlossaryItem {
//	var image: Image {
//		switch self {
//		case .radixnetwork:
//		case .radquest:
//		case .tokens:
//		case .nfts:
//		case .web3:
//		case .accounts:
//		case .personas:
//		case .radixwallet:
//		case .dapps:
//		case .transactions:
//		case .transactionfee:
//		case .xrd:
//		case .badges:
//		case .transfers:
//		case .dex:
//		case .guarantees:
//		case .networkstaking:
//		case .validators:
//		case .radixconnector:
//		case .connectbutton:
//		case .dashboard:
//		case .bridging:
//		}
//	}

	var string: String {
		switch self {
		case .radixnetwork:
			L10n.InfoLink.Glossary.radixnetwork
		case .radquest:
			L10n.InfoLink.Glossary.radquest
		case .tokens:
			L10n.InfoLink.Glossary.tokens
		case .nfts:
			L10n.InfoLink.Glossary.nfts
		case .web3:
			L10n.InfoLink.Glossary.web3
		case .accounts:
			L10n.InfoLink.Glossary.accounts
		case .personas:
			L10n.InfoLink.Glossary.personas
		case .radixwallet:
			L10n.InfoLink.Glossary.radixwallet
		case .dapps:
			L10n.InfoLink.Glossary.dapps
		case .transactions:
			L10n.InfoLink.Glossary.transactions
		case .transactionfee:
			L10n.InfoLink.Glossary.transactionfee
		case .xrd:
			L10n.InfoLink.Glossary.xrd
		case .badges:
			L10n.InfoLink.Glossary.badges
		case .transfers:
			L10n.InfoLink.Glossary.transfers
		case .dex:
			L10n.InfoLink.Glossary.dex
		case .guarantees:
			L10n.InfoLink.Glossary.guarantees
		case .networkstaking:
			L10n.InfoLink.Glossary.networkstaking
		case .validators:
			L10n.InfoLink.Glossary.validators
		case .radixconnector:
			L10n.InfoLink.Glossary.radixconnector
		case .connectbutton:
			L10n.InfoLink.Glossary.connectbutton
		case .dashboard:
			L10n.InfoLink.Glossary.dashboard
		case .bridging:
			L10n.InfoLink.Glossary.bridging
		}
	}
}

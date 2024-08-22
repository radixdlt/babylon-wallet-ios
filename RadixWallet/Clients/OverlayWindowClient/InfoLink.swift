import Foundation

// MARK: - OverlayWindowClient.GlossaryItem
extension OverlayWindowClient {
	public enum GlossaryItem: String, Sendable {
		case tokens
		case nfts
		case networkstaking
		case personas
		case dapps
		case guarantees
		case badges
		case poolunits
		case gateways
		case radixconnect
		case transactionfee
		case behaviors
		case claimnfts
		case liquidstakeunits
		case radixnetwork
		case accounts
		case radixwallet
		case transactions
		case dex
		case validators
		case radixconnector
		case connectbutton
		case xrd
		case web3
		case transfers
		case dashboard
		case bridging
		case payingaccount
	}
}

extension OverlayWindowClient.GlossaryItem {
	private static let fieldName = "glossaryAnchor"

	public init?(url: URL) {
		guard url.scheme == nil, url.host == nil, url.pathComponents.isEmpty, let query = url.query() else {
			return nil
		}

		let parts = query.split(separator: "=")
		guard parts.count == 2, String(parts[0]) == Self.fieldName else { return nil }

		guard let item = Self(rawValue: String(parts[1])) else { return nil }
		self = item
	}

	var image: ImageAsset? {
		switch self {
		case .nfts:
			AssetResource.nft
		case .networkstaking:
			AssetResource.stakes
		case .badges:
			AssetResource.iconPackageOwnerBadge
		case .poolunits:
			AssetResource.poolUnits
		case .radixnetwork:
			AssetResource.fungibleTokens
		default:
			nil
		}
	}

	var string: String {
		switch self {
		case .tokens:
			L10n.InfoLink.Glossary.tokens
		case .nfts:
			L10n.InfoLink.Glossary.nfts
		case .networkstaking:
			L10n.InfoLink.Glossary.networkstaking
		case .personas:
			L10n.InfoLink.Glossary.personas
		case .dapps:
			L10n.InfoLink.Glossary.dapps
		case .guarantees:
			L10n.InfoLink.Glossary.guarantees
		case .badges:
			L10n.InfoLink.Glossary.badges
		case .poolunits:
//			L10n.InfoLink.Glossary.poolunits
			"FIXME: String"
		case .gateways:
//			L10n.InfoLink.Glossary.gateways
			"FIXME: String"
		case .radixconnect:
//			L10n.InfoLink.Glossary.radixconnect
			"FIXME: String"
		case .transactionfee:
			L10n.InfoLink.Glossary.transactionfee
		case .behaviors:
//			L10n.InfoLink.Glossary.behaviors
			"FIXME: String"
		case .claimnfts:
//			L10n.InfoLink.Glossary.claimnfts
			"FIXME: String"
		case .liquidstakeunits:
//			L10n.InfoLink.Glossary.liquidstakeunits
			"FIXME: String"
		case .radixnetwork:
			L10n.InfoLink.Glossary.radixnetwork
		case .accounts:
			L10n.InfoLink.Glossary.accounts
		case .radixwallet:
			L10n.InfoLink.Glossary.radixwallet
		case .transactions:
			L10n.InfoLink.Glossary.transactions
		case .dex:
			L10n.InfoLink.Glossary.dex
		case .validators:
			L10n.InfoLink.Glossary.validators
		case .radixconnector:
			L10n.InfoLink.Glossary.radixconnector
		case .connectbutton:
			L10n.InfoLink.Glossary.connectbutton
		case .xrd:
			L10n.InfoLink.Glossary.xrd
		case .web3:
			L10n.InfoLink.Glossary.web3
		case .transfers:
			L10n.InfoLink.Glossary.transfers
		case .dashboard:
			L10n.InfoLink.Glossary.dashboard
		case .bridging:
			L10n.InfoLink.Glossary.bridging
		case .payingaccount:
//			L10n.InfoLink.Glossary.payingaccount
			"FIXME: String"
		}
	}
}

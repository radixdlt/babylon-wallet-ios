import Foundation

// MARK: - InfoLinkSheet
public struct InfoLinkSheet: FeatureReducer {
	public struct State: Sendable, Hashable {
		public let image: ImageAsset?
		public let text: String

		init(glossaryItem: InfoLinkSheet.GlossaryItem) {
			self.image = glossaryItem.image
			self.text = glossaryItem.string
		}
	}

	public enum ViewAction: Equatable, Sendable {
		case infoLinkTapped(InfoLinkSheet.GlossaryItem)
	}

	@Dependency(\.overlayWindowClient) var overlayWindowClient

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .infoLinkTapped(item):
			state = .init(glossaryItem: item)
			return .none
		}
	}
}

// MARK: InfoLinkSheet.GlossaryItem
extension InfoLinkSheet {
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

extension InfoLinkSheet.GlossaryItem {
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
		case .tokens:
			AssetResource.fungibleTokens
		case .xrd:
			AssetResource.xrd
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
			L10n.InfoLink.Glossary.poolunits
		case .gateways:
			L10n.InfoLink.Glossary.gateways
		case .radixconnect:
			L10n.InfoLink.Glossary.radixconnect
		case .transactionfee:
			L10n.InfoLink.Glossary.transactionfee
		case .behaviors:
			L10n.InfoLink.Glossary.behaviors
		case .claimnfts:
			L10n.InfoLink.Glossary.claimnfts
		case .liquidstakeunits:
			L10n.InfoLink.Glossary.liquidstakeunits
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
			L10n.InfoLink.Glossary.payingaccount
		}
	}
}

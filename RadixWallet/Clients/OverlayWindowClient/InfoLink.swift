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
			radixconnectString
		case .linkingNewAccount:
			linkingNewAccountString
		}
	}
}

extension OverlayWindowClient.InfoLink.GlossaryItem {
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

let linkingNewAccountString = """
# Why your Accounts will be linked
Paying your transaction fee from this Account will make you [poolunit](?glossaryAnchor=poolunit) identifiable on ledger as both the owner of the fee-paying Account and all other Accounts you use in this transaction.

*This* is _because_ you’ll **sign** the transactions on [github](https://github.com) from each [transaction fee ⓘ](infolink://transactionfee) at the same time, so your Accounts will be linked together in the transaction record.
"""

let poolunitString = """
# Pool Units
Pool units are fungible tokens that represent the proportional size of a user's contribution to a liquidity pool (LP).

Pool units are redeemable for the user's portion of the LP, but can also be traded, sold and used in DeFi applications.
"""

let gatewaysString = """
# Gateways
Gateways are your connection to blockchain networks – they enable users to communicate with the Radix Network and transfer data to and from it. As there are multiple different networks within the Radix ecosystem (for example, the Stokenet test environment or the Babylon mainnet), there a multiple gateways providing access to each one.
"""

let radixconnectString = """
# Radix Connect
Radix Connect enables users to link their Radix Wallet to desktop dApps.
"""

let transactionfeeString = """
# Transaction Fee

## Network fee
These go to Radix node operators who validate transactions and secure the Radix Network. Network fees reflect the size of the transaction.

## Royalty fee
These are set by developers and allow them to collect a “use fee” every time their work is used in a transaction.

## Tip
These are optional payments you can make directly to validators to speed up transactions. [pool unit ⓘ](infolink://poolunit)
"""

let securityshieldString = """
# Security Shields
Security Shields are a combination of security factors you use to sign transactions, and recover locked Accounts and Personas. You'll need to pay a small transaction fee to apply one to the Radix Network.
"""

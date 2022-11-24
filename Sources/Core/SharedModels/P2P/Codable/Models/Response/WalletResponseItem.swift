import Foundation

// MARK: - P2P.ToDapp
public extension P2P {
	/// Just a namespace
	enum ToDapp {}
}

// MARK: - P2P.ToDapp.WalletResponseItem
public extension P2P.ToDapp {
	/// `WalletResponseItem` in [CAP21][cap]
	///
	/// [cap]: https://radixdlt.atlassian.net/wiki/spaces/AT/pages/2712895489/CAP-21+Message+format+between+dApp+and+wallet#Wallet-SDK-%E2%86%94%EF%B8%8F-Wallet-messages
	///
	enum WalletResponseItem: Sendable, Hashable, Encodable {
		/// Response to Dapp from wallet, info about a users accounts.
		/// [cap]: https://radixdlt.atlassian.net/wiki/spaces/AT/pages/2712895489/CAP-21+Message+format+between+dApp+and+wallet#Wallet-SDK-%E2%86%94%EF%B8%8F-Wallet-messages
		///
		case oneTimeAccountAddresses(OneTimeAccountAddressesResponse)

		/// Response to Dapp from wallet, info about a signed and submitted transaction.
		///
		/// Called `SendTransactionResponse` in [CAP21][cap]
		///
		/// [cap]: https://radixdlt.atlassian.net/wiki/spaces/AT/pages/2712895489/CAP-21+Message+format+between+dApp+and+wallet#Wallet-SDK-%E2%86%94%EF%B8%8F-Wallet-messages
		///
		case signTransaction(SignTransactionResponse)
	}
}

// MARK: Encodable
private extension P2P.ToDapp.WalletResponseItem {
	typealias Discriminator = P2P.FromDapp.Discriminator
	var discriminator: Discriminator {
		switch self {
		case .oneTimeAccountAddresses: return .oneTimeAccountAddresses
		case .signTransaction: return .signTransaction
		}
	}

	enum CodingKeys: String, CodingKey {
		// Yes the JSON Key is `requestType` and not `responseType`.
		case disciminator = "requestType"
	}
}

public extension P2P.ToDapp.WalletResponseItem {
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(discriminator, forKey: .disciminator)
		switch self {
		case let .oneTimeAccountAddresses(response):
			try response.encode(to: encoder)
		case let .signTransaction(response):
			try response.encode(to: encoder)
		}
	}
}

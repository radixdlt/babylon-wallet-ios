import Foundation
import Tagged

// MARK: - P2P.FromDapp
public extension P2P {
	/// Just a namespace
	enum FromDapp {}
}

// MARK: - P2P.FromDapp.WalletRequestItem
public extension P2P.FromDapp {
	/// `WalletRequestItem` in [CAP21][cap]
	///
	/// [cap]: https://radixdlt.atlassian.net/wiki/spaces/AT/pages/2712895489/CAP-21+Message+format+between+dApp+and+wallet#Wallet-SDK-%E2%86%94%EF%B8%8F-Wallet-messages
	///
	enum WalletRequestItem: Sendable, Hashable, Decodable {
		/// Request from Dapp to wallet, to sign a transaction
		///
		/// Called `SendTransaction` in [CAP21][cap]
		///
		/// [cap]: https://radixdlt.atlassian.net/wiki/spaces/AT/pages/2712895489/CAP-21+Message+format+between+dApp+and+wallet#Wallet-SDK-%E2%86%94%EF%B8%8F-Wallet-messages
		///
		case sendTransaction(SendTransactionWriteRequestItem)

		case oneTimeAccounts(OneTimeAccountsReadRequestItem)
	}
}

internal extension P2P.FromDapp.WalletRequestItem {
	var discriminator: P2P.FromDapp.Discriminator {
		switch self {
		case .sendTransaction: return .sendTransactionWrite
		case .oneTimeAccounts: return .oneTimeAccountsRead
		}
	}
}

// MARK: As OneTimeAccountsReadRequestItem
public extension P2P.FromDapp.WalletRequestItem {
	var oneTimeAccounts: P2P.FromDapp.OneTimeAccountsReadRequestItem? {
		guard case let .oneTimeAccounts(request) = self else {
			return nil
		}
		return request
	}

	struct ExpectedOneTimeAccountAddressesRequest: Swift.Error {}
	func asOneTimeAccountAddresses() throws -> P2P.FromDapp.OneTimeAccountsReadRequestItem {
		guard let oneTimeAccounts else {
			throw ExpectedOneTimeAccountAddressesRequest()
		}
		return oneTimeAccounts
	}
}

// MARK: As SendTransactionWriteRequestItem
public extension P2P.FromDapp.WalletRequestItem {
	var sendTransaction: P2P.FromDapp.SendTransactionWriteRequestItem? {
		guard case let .sendTransaction(request) = self else {
			return nil
		}
		return request
	}

	struct ExpectedSignTransactionRequest: Swift.Error {}
	func asSignTransaction() throws -> P2P.FromDapp.SendTransactionWriteRequestItem {
		guard let sendTransaction else {
			throw ExpectedSignTransactionRequest()
		}
		return sendTransaction
	}
}

// MARK: Encodable
private extension P2P.FromDapp.WalletRequestItem {
	typealias Discriminator = P2P.FromDapp.Discriminator

	enum CodingKeys: String, CodingKey {
		case discriminator = "requestType"
	}
}

public extension P2P.FromDapp.WalletRequestItem {
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let discriminator = try container.decode(Discriminator.self, forKey: .discriminator)
		switch discriminator {
		case .oneTimeAccountsRead:
			self = try .oneTimeAccounts(P2P.FromDapp.OneTimeAccountsReadRequestItem(from: decoder))
		case .sendTransactionWrite:
			self = try .sendTransaction(P2P.FromDapp.SendTransactionWriteRequestItem(from: decoder))
		}
	}
}

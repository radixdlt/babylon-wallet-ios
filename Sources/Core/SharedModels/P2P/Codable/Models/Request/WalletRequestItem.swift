//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-11-16.
//

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
		case signTransaction(SignTransactionRequest)

		case oneTimeAccountAddresses(OneTimeAccountAddressesRequest)
	}
}

// MARK: As OneTimeAccountAddressesRequest
public extension P2P.FromDapp.WalletRequestItem {
	var oneTimeAccountAddresses: P2P.FromDapp.OneTimeAccountAddressesRequest? {
		guard case let .oneTimeAccountAddresses(request) = self else {
			return nil
		}
		return request
	}

	struct ExpectedOneTimeAccountAddressesRequest: Swift.Error {}
	func asOneTimeAccountAddresses() throws -> P2P.FromDapp.OneTimeAccountAddressesRequest {
		guard let oneTimeAccountAddresses else {
			throw ExpectedOneTimeAccountAddressesRequest()
		}
		return oneTimeAccountAddresses
	}
}

// MARK: As SignTransactionRequest
public extension P2P.FromDapp.WalletRequestItem {
	var signTransaction: P2P.FromDapp.SignTransactionRequest? {
		guard case let .signTransaction(request) = self else {
			return nil
		}
		return request
	}

	struct ExpectedSignTransactionRequest: Swift.Error {}
	func asSignTransaction() throws -> P2P.FromDapp.SignTransactionRequest {
		guard let signTransaction else {
			throw ExpectedSignTransactionRequest()
		}
		return signTransaction
	}
}

// MARK: Encodable
private extension P2P.FromDapp.WalletRequestItem {
	typealias Discriminator = P2P.FromDapp.Discriminator

	enum CodingKeys: String, CodingKey {
		case disciminator = "requestType"
	}
}

public extension P2P.FromDapp.WalletRequestItem {
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let discriminator = try container.decode(Discriminator.self, forKey: .disciminator)
		switch discriminator {
		case .ongoingAccountAddresses:
			self = try .oneTimeAccountAddresses(P2P.FromDapp.OneTimeAccountAddressesRequest(from: decoder))
		case .signTransaction:
			self = try .signTransaction(P2P.FromDapp.SignTransactionRequest(from: decoder))
		}
	}
}

//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-11-16.
//

import EngineToolkit
import Foundation
import Profile

// MARK: - P2PFromDappWalletRequestItemProtocol
/// Empty Marker protocol
public protocol P2PFromDappWalletRequestItemProtocol: Sendable, Hashable {}

// MARK: - P2P.FromDapp.SignTransactionRequest
public extension P2P.FromDapp {
	/// Request from Dapp to wallet, to sign a transaction
	///
	/// Called `SendTransaction` in [CAP21][cap]
	///
	/// [cap]: https://radixdlt.atlassian.net/wiki/spaces/AT/pages/2712895489/CAP-21+Message+format+between+dApp+and+wallet#Wallet-SDK-%E2%86%94%EF%B8%8F-Wallet-messages
	///
	struct SignTransactionRequest: Sendable, Hashable, Decodable, P2PFromDappWalletRequestItemProtocol {
		public let version: Version

		public let transactionManifest: String
		public let blobs: [HexCodable]

		public let message: String?

		public init(version: Version, transactionManifest: String, blobs: [HexCodable], message: String?) {
			self.version = version
			self.transactionManifest = transactionManifest
			self.blobs = blobs
			self.message = message
		}
	}
}

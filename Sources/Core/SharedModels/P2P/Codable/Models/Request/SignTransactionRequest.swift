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

		public let transactionManifestString: String
		public let blobsHex: [String]

		public let message: String?

		public init(
			version: Version,
			transactionManifestString: String,
			blobsHex: [String] = [],
			message: String?
		) {
			self.version = version
			self.transactionManifestString = transactionManifestString
			self.blobsHex = blobsHex
			self.message = message
		}
	}
}

public extension P2P.FromDapp.SignTransactionRequest {
	private enum CodingKeys: String, CodingKey {
		case blobsHex = "blobs"
		case message
		case transactionManifestString = "transactionManifest"
		case version
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		try self.init(
			version: container.decode(Version.self, forKey: .version),
			transactionManifestString: container.decode(String.self, forKey: .transactionManifestString),
			blobsHex: container.decodeIfPresent([String].self, forKey: .blobsHex) ?? [],
			message: container.decodeIfPresent(String.self, forKey: .message)
		)
	}
}

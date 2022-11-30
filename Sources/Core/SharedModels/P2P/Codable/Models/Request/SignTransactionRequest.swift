import EngineToolkit
import Foundation
import Profile

// MARK: - P2PFromDappWalletRequestItemProtocol
/// Empty Marker protocol
public protocol P2PFromDappWalletRequestItemProtocol: Sendable, Hashable {}

// MARK: - P2P.FromDapp.SendTransactionWriteRequestItem
public extension P2P.FromDapp {
	/// Request from Dapp to wallet, to sign a transaction
	///
	/// Called `SendTransaction` in [CAP21][cap]
	///
	/// [cap]: https://radixdlt.atlassian.net/wiki/spaces/AT/pages/2712895489/CAP-21+Message+format+between+dApp+and+wallet#Wallet-SDK-%E2%86%94%EF%B8%8F-Wallet-messages
	///
	struct SendTransactionWriteRequestItem: Sendable, Hashable, Decodable, P2PFromDappWalletRequestItemProtocol {
		public let version: Version

		public let transactionManifest: TransactionManifest
		public let message: String?

		public init(
			transactionManifest: TransactionManifest,
			version: Version,
			message: String?
		) {
			self.version = version
			self.transactionManifest = transactionManifest
			self.message = message
		}
	}
}

public extension P2P.FromDapp.SendTransactionWriteRequestItem {
	private enum CodingKeys: String, CodingKey {
		case blobsHex = "blobs"
		case message
		case transactionManifestString = "transactionManifest"
		case version
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let manifestString = try container.decode(String.self, forKey: .transactionManifestString)
		let blobsHex = try container.decodeIfPresent([String].self, forKey: .blobsHex) ?? []

		let manifest = try TransactionManifest(
			instructions: .string(manifestString),
			blobs: blobsHex.map {
				try [UInt8](Data(hexString: $0))
			}
		)

		try self.init(
			transactionManifest: manifest,
			version: container.decode(Version.self, forKey: .version),
			message: container.decodeIfPresent(String.self, forKey: .message)
		)
	}
}

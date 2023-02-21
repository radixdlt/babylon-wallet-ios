import EngineToolkitModels
import Prelude

// MARK: - P2P.FromDapp.SendTransactionWriteRequestItem
extension P2P.FromDapp.WalletInteraction {
	public struct SendTransactionItem: Sendable, Hashable, Decodable {
		public let transactionManifest: TransactionManifest
		public let version: TXVersion
		public let message: String?

		public init(
			version: TXVersion,
			transactionManifest: TransactionManifest,
			message: String?
		) {
			self.version = version
			self.transactionManifest = transactionManifest
			self.message = message
		}

		private enum CodingKeys: String, CodingKey {
			case transactionManifestString = "transactionManifest"
			case version
			case blobsHex = "blobs"
			case message
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)

			let manifestString = try container.decode(String.self, forKey: .transactionManifestString)
			let blobsHex = try container.decodeIfPresent([String].self, forKey: .blobsHex) ?? []

			let manifest = try TransactionManifest(
				instructions: .string(manifestString),
				blobs: blobsHex.map {
					try [UInt8](Data(hex: $0))
				}
			)

			try self.init(
				version: container.decode(TXVersion.self, forKey: .version),
				transactionManifest: manifest,
				message: container.decodeIfPresent(String.self, forKey: .message)
			)
		}
	}
}

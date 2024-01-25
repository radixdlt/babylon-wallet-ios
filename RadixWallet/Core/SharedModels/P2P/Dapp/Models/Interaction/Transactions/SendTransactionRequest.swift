// MARK: - RawTransactionManifest
public struct RawTransactionManifest: Sendable, Hashable {
	public let transactionManifestString: String
	public let blobsBytes: [Data]

	public init(transactionManifestString: String, blobsBytes: [Data]) {
		self.transactionManifestString = transactionManifestString
		self.blobsBytes = blobsBytes
	}

	public init(manifest: TransactionManifest) throws {
		try self.init(
			transactionManifestString: manifest.instructions().asStr(),
			blobsBytes: manifest.blobs()
		)
	}

	public func transactionManifest(onNetwork networkID: NetworkID) throws -> TransactionManifest {
		try .init(
			instructions: .fromString(string: transactionManifestString, networkId: networkID.rawValue),
			blobs: blobsBytes
		)
	}
}

// MARK: - P2P.Dapp.Request.SendTransactionItem
extension P2P.Dapp.Request {
	public struct SendTransactionItem: Sendable, Hashable, Decodable {
		public let rawTransactionManifest: RawTransactionManifest
		public let version: TXVersion
		public let message: String?

		public init(
			version: TXVersion,
			rawTransactionManifest: RawTransactionManifest,
			message: String?
		) {
			self.version = version
			self.rawTransactionManifest = rawTransactionManifest
			self.message = message
		}

		public init(
			version: TXVersion = .default,
			transactionManifest: TransactionManifest,
			message: String? = nil
		) throws {
			try self.init(
				version: version,
				rawTransactionManifest: .init(
					transactionManifestString: transactionManifest.instructions().asStr(),
					blobsBytes: transactionManifest.blobs()
				),
				message: message
			)
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
			let blobsBytes = try blobsHex.map { try Data(hex: $0) }

			try self.init(
				version: container.decode(TXVersion.self, forKey: .version),
				rawTransactionManifest: .init(transactionManifestString: manifestString, blobsBytes: blobsBytes),
				message: container.decodeIfPresent(String.self, forKey: .message)
			)
		}
	}
}

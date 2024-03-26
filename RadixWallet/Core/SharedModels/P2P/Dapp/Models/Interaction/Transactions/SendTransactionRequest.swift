// MARK: - UnvalidatedTransactionManifest
public struct UnvalidatedTransactionManifest: Sendable, Hashable {
	public let transactionManifestString: String
	public let blobs: Blobs

	public init(transactionManifestString: String, blobsBytes: [Data]) {
		self.transactionManifestString = transactionManifestString
		self.blobs = Blobs(blobsBytes.map(Blob.init(data:)))
	}

	public init(manifest: TransactionManifest) {
		self.transactionManifestString = manifest.instructionsString
		self.blobs = manifest.blobs
	}

	public func transactionManifest(
		onNetwork networkID: NetworkID
	) throws -> TransactionManifest {
		try .init(
			instructionsString: transactionManifestString,
			networkID: networkID,
			blobs: blobs
		)
	}
}

// MARK: - P2P.Dapp.Request.SendTransactionItem
extension P2P.Dapp.Request {
	public struct SendTransactionItem: Sendable, Hashable, Decodable {
		public let unvalidatedManifest: UnvalidatedTransactionManifest
		public let version: TXVersion
		public let message: String?

		public init(
			version: TXVersion,
			unvalidatedManifest: UnvalidatedTransactionManifest,
			message: String?
		) {
			self.version = version
			self.unvalidatedManifest = unvalidatedManifest
			self.message = message
		}

		public init(
			version: TXVersion = .default,
			transactionManifest: TransactionManifest,
			message: String? = nil
		) {
			self.init(
				version: version,
				unvalidatedManifest: .init(manifest: transactionManifest),
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
				unvalidatedManifest: .init(transactionManifestString: manifestString, blobsBytes: blobsBytes),
				message: container.decodeIfPresent(String.self, forKey: .message)
			)
		}
	}
}

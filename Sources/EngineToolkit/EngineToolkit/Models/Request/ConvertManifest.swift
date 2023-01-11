// MARK: - ConvertManifestRequest
public struct ConvertManifestRequest: Sendable, Codable, Hashable {
	public let transactionVersion: TXVersion
	public let networkId: NetworkID
	public let manifestInstructionsOutputFormat: ManifestInstructionsKind
	public let manifest: TransactionManifest

	public init(
		transactionVersion: TXVersion,
		manifest: TransactionManifest,
		outputFormat: ManifestInstructionsKind,
		networkId: NetworkID
	) {
		self.transactionVersion = transactionVersion
		self.manifestInstructionsOutputFormat = outputFormat
		self.manifest = manifest
		self.networkId = networkId
	}

	private enum CodingKeys: String, CodingKey {
		case transactionVersion = "transaction_version"
		case networkId = "network_id"
		case manifestInstructionsOutputFormat = "manifest_instructions_output_format"
		case manifest
	}
}

public typealias ConvertManifestResponse = TransactionManifest

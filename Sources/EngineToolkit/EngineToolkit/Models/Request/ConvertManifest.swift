// MARK: - ConvertManifestRequest
public struct ConvertManifestRequest: Sendable, Codable, Hashable {
	public let networkId: NetworkID
	public let instructionsOutputKind: ManifestInstructionsKind
	public let manifest: TransactionManifest

	public init(
		manifest: TransactionManifest,
		outputFormat: ManifestInstructionsKind,
		networkId: NetworkID
	) {
		self.instructionsOutputKind = outputFormat
		self.manifest = manifest
		self.networkId = networkId
	}
}

extension ConvertManifestRequest {
	private enum CodingKeys: String, CodingKey {
		case networkId = "network_id"
		case instructionsOutputKind = "instructions_output_kind"
		case manifest
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(String(networkId), forKey: .networkId)
		try container.encode(instructionsOutputKind, forKey: .instructionsOutputKind)
		try container.encode(manifest, forKey: .manifest)
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let networkId: UInt8 = try decodeAndConvertToNumericType(container: container, key: .networkId)
		let instructionsOutputKind = try container.decode(ManifestInstructionsKind.self, forKey: .instructionsOutputKind)
		let manifest = try container.decode(TransactionManifest.self, forKey: .manifest)

		self.init(manifest: manifest, outputFormat: instructionsOutputKind, networkId: NetworkID(networkId))
	}
}

public typealias ConvertManifestResponse = TransactionManifest

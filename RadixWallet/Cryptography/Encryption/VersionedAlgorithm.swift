// MARK: - VersionedAlgorithm
protocol VersionedAlgorithm: Codable {
	associatedtype Version: Sendable & Hashable & Codable
	var version: Version { get }
	var description: String { get }
	init(version: Version)
}

// MARK: - VersionedAlgorithmCodingKeys
private enum VersionedAlgorithmCodingKeys: String, CodingKey {
	case version, description
}

extension VersionedAlgorithm {
	private typealias CodingKeys = VersionedAlgorithmCodingKeys

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let version = try container.decode(Version.self, forKey: .version)
		self.init(version: version)
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(version, forKey: .version)
		try container.encode(description, forKey: .description)
	}
}

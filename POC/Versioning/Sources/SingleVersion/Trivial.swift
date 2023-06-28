import Foundation

// MARK: - Trivial2
struct Trivial2: VersionedCodable {
	static let minVersion: Int = 2
	internal private(set) var version: Int = Self.minVersion
	let label: String
	let foo: String // New in version 2
}

// MARK: Codable
extension Trivial2 {
	private enum CodingKeys: String, CodingKey {
		case version
		case label
		case foo // New in version 2
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let version = try container.decode(Int.self, forKey: .version)
		self.label = try container.decode(String.self, forKey: .label)
		switch version {
		case 1:
			self.foo = "MIGRATED_FROM_\(version)"
			self.version = Self.minVersion // bump version
		case Self.minVersion:
			self.foo = try container.decode(String.self, forKey: .foo)
			self.version = version
		default:
			throw DecodingErrorUnknownVersion(
				decodedVersion: version,
				decoding: Self.self
			)
		}
	}
}

// MARK: - DecodingErrorUnknownVersion
struct DecodingErrorUnknownVersion: LocalizedError {
	let decodedVersion: Int
	let minVersion: Int
	let type: String

	init<D: VersionedCodable>(
		decodedVersion: Int,
		decoding type: D.Type = D.self
	) {
		self.decodedVersion = decodedVersion
		self.type = String(describing: type)
		self.minVersion = type.minVersion
	}

	var errorDescription: String? {
		"Failed to decode '\(type)', decoded version: '\(decodedVersion)', minVersion: '\(minVersion)'"
	}
}

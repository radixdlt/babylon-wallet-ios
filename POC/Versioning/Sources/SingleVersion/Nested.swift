import Foundation

// MARK: - Nested2
struct Nested2: Codable, Equatable {
	struct Configuration {
		let decodedVersionFromParent: Int
	}

	public static let currentVersion = 2
	internal private(set) var version: Int = Self.currentVersion
	let label: String
	let inner: Inner

	struct Inner: Encodable, DecodableWithConfiguration, Equatable {
		let foo: String
		let bar: String // New in version 2
	}
}

extension Nested2 {
	private enum CodingKeys: String, CodingKey {
		case version
		case label
		case inner
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let version = try container.decode(Int.self, forKey: .version)
		self.label = try container.decode(String.self, forKey: .label)
		self.inner = try container.decode(
			Inner.self,
			forKey: .inner,
			configuration: .init(
				decodedVersionFromParent: version
			)
		)
		self.version = Self.currentVersion
	}
}

extension Nested2.Inner {
	private enum CodingKeys: String, CodingKey {
		case foo
		case bar // New in version 2
	}

	init(from decoder: Decoder, configuration: Nested2.Configuration) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let version = configuration.decodedVersionFromParent

		self.foo = try container.decode(String.self, forKey: .foo)
		switch version {
		case 1:
			self.bar = "MIGRATED_FROM_\(version)"
		case 2:
			self.bar = try container.decode(String.self, forKey: .bar)
		default:
			throw FailedToDecodeWithConfigurationUnknownVersion()
		}
	}
}

// MARK: - FailedToDecodeWithConfigurationUnknownVersion
struct FailedToDecodeWithConfigurationUnknownVersion: Swift.Error {}

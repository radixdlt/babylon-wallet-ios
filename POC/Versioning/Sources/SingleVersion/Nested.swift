import Foundation

// MARK: - Nested
struct Nested: Codable, Equatable {
	struct Configuration {
		let decodedVersionFromParent: Int
	}

	public static let currentVersion = 3
	internal private(set) var version: Int = Self.currentVersion
	let label: String
	let inner: Inner
	let anotherInner: Inner3 // New in version 3

	struct Inner: Encodable, DecodableWithConfiguration, Equatable {
		let foo: String
		let bar: String // New in version 2
	}

	// New in version 3
	struct Inner3: Equatable, Codable {
		let bizz: String
	}
}

extension Nested {
	private enum CodingKeys: String, CodingKey {
		case version
		case label
		case inner
		case anotherInner
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
		if version < 3 {
			self.anotherInner = .init(bizz: "MIGRATED_FROM_\(version)")
		} else {
			self.anotherInner = try container.decode(Inner3.self, forKey: .anotherInner)
		}

		self.version = Self.currentVersion
	}
}

extension Nested.Inner {
	private enum CodingKeys: String, CodingKey {
		case foo
		case bar // New in version 2
	}

	init(from decoder: Decoder, configuration: Nested.Configuration) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let version = configuration.decodedVersionFromParent

		self.foo = try container.decode(String.self, forKey: .foo)
		if version < 2 {
			self.bar = "MIGRATED_FROM_\(version)"
		} else {
			self.bar = try container.decode(String.self, forKey: .bar)
		}
	}
}

import Foundation

// MARK: - Model
/// This is a demonstration of versioning where we have a single global version number put in the
/// root of the `Model`, which is then passed to children using `init:from:configuration`
/// decoding init part of the `DecodableWithConfiguration` protcocol introduced in iOS 15.
struct Model: Codable, Equatable {
	static let currentVersion = 3

	let version: Int
	let label: String
	let inner: Inner
	let anotherInner: Inner3 // New in version 3

	init(
		version: Int = Self.currentVersion,
		label: String,
		inner: Inner,
		anotherInner: Inner3
	) {
		self.version = version
		self.label = label
		self.inner = inner
		self.anotherInner = anotherInner
	}
}

// MARK: Model.Configuration
extension Model {
	struct Configuration {
		let decodedVersionFromParent: Int
	}
}

extension Model {
	struct Inner: Encodable, DecodableWithConfiguration, Equatable {
		let foo: String
		let bar: String // New in version 2
	}

	// New in version 3
	struct Inner3: Equatable, Codable {
		let bizz: String
	}
}

extension Model {
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

extension Model.Inner {
	private enum CodingKeys: String, CodingKey {
		case foo
		case bar // New in version 2
	}

	init(from decoder: Decoder, configuration: Model.Configuration) throws {
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

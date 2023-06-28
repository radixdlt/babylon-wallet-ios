import Foundation

// MARK: - VersionedModel
protocol VersionedModel: Codable, Equatable {
	static var currentVersion: Int { get }
	var version: Int { get }
}

// MARK: - Model
/// This is a demonstration of versioning where we version every child model type of the root, and the root iteself.
struct Model: VersionedModel {
	static let currentVersion = 2

	let version: Int
	let label: String
	let inner: Inner
	let anotherInner: Inner2 // New in `Model.version: 2`

	init(
		version: Int = Self.currentVersion,
		label: String,
		inner: Inner,
		anotherInner: Inner2
	) {
		self.version = version
		self.label = label
		self.inner = inner
		self.anotherInner = anotherInner
	}
}

extension Model {
	struct Inner: VersionedModel {
		static let currentVersion = 2
		let version: Int
		let foo: String
		let bar: String // New in `Model.Inner.version: 2`

		init(version: Int = Self.currentVersion, foo: String, bar: String) {
			self.version = version
			self.foo = foo
			self.bar = bar
		}
	}

	// New in `Model.version: 2`
	struct Inner2: VersionedModel {
		static let currentVersion = 1
		let version: Int
		let bizz: String

		init(version: Int = Self.currentVersion, bizz: String) {
			self.version = version
			self.bizz = bizz
		}
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
		self.inner = try container.decode(Inner.self, forKey: .inner)
		if version < 2 {
			self.anotherInner = .init(bizz: "MIGRATED_FROM_\(version)")
		} else {
			self.anotherInner = try container.decode(Inner2.self, forKey: .anotherInner)
		}

		self.version = Self.currentVersion
	}
}

extension Model.Inner {
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let version = try container.decode(Int.self, forKey: .version)

		self.foo = try container.decode(String.self, forKey: .foo)
		if version < 2 {
			self.bar = "MIGRATED_FROM_\(version)"
		} else {
			self.bar = try container.decode(String.self, forKey: .bar)
		}
		self.version = Self.currentVersion
	}
}

import Foundation
import VersionedCodable

typealias Model = ModelV3

// MARK: - ModelV3
struct ModelV3: VersionedCodable, Equatable {
	let label: String
	let inner: Inner
	let anotherInner: AnotherInner // New in version

	init(label: String, inner: Inner, anotherInner: AnotherInner) {
		self.label = label
		self.inner = inner
		self.anotherInner = anotherInner
	}

	static let version: Int? = 3
	typealias PreviousVersion = ModelV2
	init(from prev: PreviousVersion) throws {
		self.init(
			label: prev.label,
			inner: prev.inner,
			anotherInner: .init(
				bizz: "MIGRATED_FROM_\(PreviousVersion.version!)"
			)
		)
	}
}

// MARK: Nested
extension Model {
	typealias Inner = InnerV2
	struct InnerV2: VersionedCodable, Equatable {
		let foo: String
		let bar: String // New in version 2
		init(foo: String, bar: String) {
			self.foo = foo
			self.bar = bar
		}

		static let version: Int? = 2
		typealias PreviousVersion = InnerV1
		init(from prev: PreviousVersion) throws {
			self.init(
				foo: prev.foo,
				bar: "MIGRATED_FROM_\(PreviousVersion.version!)"
			)
		}
	}

	// New in version 3
	typealias AnotherInner = AnotherInnerV1
	struct AnotherInnerV1: VersionedCodable, Equatable {
		let bizz: String
		init(bizz: String) {
			self.bizz = bizz
		}

		static let version: Int? = 1
		typealias PreviousVersion = NothingEarlier
	}
}

// MARK: Older
extension Model {
	struct ModelV2: VersionedCodable, Equatable {
		let label: String
		let inner: InnerV2
		init(label: String, inner: InnerV2) {
			self.label = label
			self.inner = inner
		}

		static let version: Int? = 2
		typealias PreviousVersion = ModelV1
		init(from prev: PreviousVersion) throws {
			try self.init(
				label: prev.label,
				inner: .init(from: prev.inner)
			)
		}
	}

	struct ModelV1: VersionedCodable, Equatable {
		let label: String
		let inner: InnerV1
		init(label: String, inner: InnerV1) {
			self.label = label
			self.inner = inner
		}

		static let version: Int? = 1
		typealias PreviousVersion = NothingEarlier
	}
}

// MARK: - Model.InnerV1
extension Model {
	struct InnerV1: VersionedCodable, Equatable {
		let foo: String
		init(foo: String) {
			self.foo = foo
		}

		static let version: Int? = 1
		typealias PreviousVersion = NothingEarlier
	}
}

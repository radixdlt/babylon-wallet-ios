import Foundation
import VersionedCodable

typealias Model = ModelV3

typealias GenericType<Value: Codable & Equatable> = GenericTypeV2<Value>

// MARK: - GenericTypeV2
struct GenericTypeV2<Value>: VersionedCodable, Equatable where Value: Codable & Equatable {
	let value: Value
	init(value: Value) {
		self.value = value
	}

	static var version: Int? { 2 }
	typealias PreviousVersion = GenericTypeV1<Value>
	init(from prev: PreviousVersion) throws {
		self.init(value: prev.valeu)
	}
}

// MARK: - GenericTypeV1
struct GenericTypeV1<Value>: VersionedCodable, Equatable where Value: Codable & Equatable {
	let valeu: Value // SIC: typo fixed in v2
	static var version: Int? { 1 }
	typealias PreviousVersion = NothingEarlier
}

// MARK: - ModelV3
/// This demonstrates versioning using multiple types for each model version, using the lib
/// `VersionedCodable` to not have to write as much code.
struct ModelV3: VersionedCodable, Equatable {
	let label: String
	let inner: Inner
	let anotherInner: AnotherInner // New

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
		let innerGeneric: GenericTypeV2<String>
		init(innerGeneric: GenericTypeV2<String>) {
			self.innerGeneric = innerGeneric
		}

		static let version: Int? = 2
		typealias PreviousVersion = InnerV1
		init(from prev: PreviousVersion) throws {
			try self.init(
				innerGeneric: .init(from: prev.innerGeneric)
			)
		}
	}

	typealias AnotherInner = AnotherInnerV1

	// New
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
		let inner: InnerV2 // New
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
		let innerGeneric: GenericTypeV1<String>
		init(innerGeneric: GenericTypeV1<String>) {
			self.innerGeneric = innerGeneric
		}

		static let version: Int? = 1
		typealias PreviousVersion = NothingEarlier
	}
}

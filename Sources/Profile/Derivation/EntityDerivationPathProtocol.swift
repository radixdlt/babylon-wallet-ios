import Cryptography
import EngineToolkitModels
import Prelude

// MARK: - CannotCreateDerivationPathEntityIndexIsOutOfBound
struct CannotCreateDerivationPathEntityIndexIsOutOfBound: Swift.Error {}

extension HD.Path.Component.Child {
	public static let bip44Purpose: Self = .init(nonHardenedValue: 44, isHardened: true)

	public static let coinType: Self = .init(nonHardenedValue: 1022, isHardened: true)

	/// The last component of the special purpose derivation path component uesd by factor sources as identifier,
	/// according to [CAP-26][cap26], the format is:
	///
	///     `m/44'/1022'/365'
	///
	/// Where `'` denotes hardened path, which is **required** as per [SLIP-10][slip10],
	/// where `365` is ASCII sum of `"GETID"`, i.e. `"GETID".map{ $0.asciiValue! }.reduce(0, +)`
	///
	/// [cap26]: https://radixdlt.atlassian.net/l/cp/UNaBAGUC
	/// [slip10]: https://github.com/satoshilabs/slips/blob/master/slip-0010.md
	///
	public static let getID: Self = .init(nonHardenedValue: 365, isHardened: true)
}

extension HD.Path.Full {
	/// Special purpose derivation path component uesd by factor sources as identifier,
	/// according to [CAP-26][cap26], the format is:
	///
	///     `m/44'/1022'/365'
	///
	/// Where `'` denotes hardened path, which is **required** as per [SLIP-10][slip10],
	/// where `365` is ASCII sum of `"GETID"`, i.e. `"GETID".map{ $0.asciiValue! }.reduce(0, +)`
	///
	/// [cap26]: https://radixdlt.atlassian.net/l/cp/UNaBAGUC
	/// [slip10]: https://github.com/satoshilabs/slips/blob/master/slip-0010.md
	///
	public static let getID = try! Self(
		children: [
			.bip44Purpose,
			.coinType,
			.getID,
		],
		onlyPublic: false
	)

	public static func identity(
		networkID: NetworkID,
		index: Profile.Network.NextDerivationIndices.Index,
		keyKind: KeyKind
	) throws -> Self {
		try .defaultForEntity(
			networkID: networkID,
			entityKind: .identity,
			index: index,
			keyKind: keyKind
		)
	}

	public static func account(
		networkID: NetworkID,
		index: Profile.Network.NextDerivationIndices.Index,
		keyKind: KeyKind
	) throws -> Self {
		try .defaultForEntity(
			networkID: networkID,
			entityKind: .account,
			index: index,
			keyKind: keyKind
		)
	}

	public static func defaultForEntity(
		networkID: NetworkID,
		entityKind: EntityKind,
		index unboundIndex: Profile.Network.NextDerivationIndices.Index,
		keyKind: KeyKind
	) throws -> Self {
		guard
			unboundIndex >= 0,
			Int(HierarchicalDeterministic.Path.Component.Child.Value.max) > unboundIndex
		else {
			throw CannotCreateDerivationPathEntityIndexIsOutOfBound()
		}
		let index = HierarchicalDeterministic.Path.Component.Child.Value(unboundIndex)
		let isHardened = true
		return try Self(
			children: [
				.bip44Purpose,
				.coinType,
				.init(nonHardenedValue: networkID.derivationPathComponentNonHardenedValue, isHardened: isHardened),
				.init(nonHardenedValue: entityKind.derivationPathComponentNonHardenedValue, isHardened: isHardened),
				.init(nonHardenedValue: keyKind.derivationPathComponentNonHardenedValue, isHardened: isHardened),
				.init(nonHardenedValue: index, isHardened: isHardened),
			],
			onlyPublic: false
		)
	}
}

// MARK: - EntityDerivationPathProtocol
public protocol EntityDerivationPathProtocol: DerivationPathSchemeProtocol {
	associatedtype Entity: EntityProtocol
	var fullPath: HD.Path.Full { get }
	init(
		networkID: NetworkID,
		index: Profile.Network.NextDerivationIndices.Index,
		keyKind: KeyKind
	) throws

	init(
		fullPath: HD.Path.Full
	) throws

	func switching(keyKind newKeyKind: KeyKind) throws -> Self
}

extension EntityDerivationPathProtocol {
	public func switching(keyKind newKeyKind: KeyKind) throws -> Self {
		try Self(networkID: networkID, index: index, keyKind: newKeyKind)
	}

	public var derivationPath: String { fullPath.toString() }
	public static var derivationScheme: DerivationScheme { .slip10 }
	public static var purpose: DerivationPurpose { .publicKeyForAddressOfEntity(type: Entity.self) }

	public var networkID: NetworkID {
		guard let networkID = NetworkID(exactly: self[.networkIndex]) else {
			fatalError("Expected to always have a valid networkID")
		}
		return networkID
	}

	public var entityKind: EntityKind {
		guard let entityKind = EntityKind(rawValue: self[.entityKindIndex]) else {
			fatalError("Expected to always have a valid entityKind")
		}
		return entityKind
	}

	public var keyKind: KeyKind {
		guard let keyKind = KeyKind(rawValue: self[.keyKindIndex]) else {
			fatalError("Expected to always have a valid keyKind")
		}
		return keyKind
	}

	public var index: HD.Path.Component.Child.Value {
		self[.entityIndexIndex]
	}

	subscript(index: EntityDerivationPathComponentIndex) -> HD.Path.Component.Child.Value {
		fullPath[index]
	}
}

extension HD.Path.Full {
	fileprivate subscript(index: EntityDerivationPathComponentIndex) -> HD.Path.Component.Child {
		children[index.rawValue]
	}

	fileprivate subscript(index: EntityDerivationPathComponentIndex) -> HD.Path.Component.Child.Value {
		self[index].nonHardenedValue
	}
}

extension DerivationPathProtocol where Self: Encodable {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(derivationPath)
	}
}

extension DerivationPathProtocol where Self: Decodable {
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let derivationPath = try container.decode(String.self)
		try self.init(derivationPath: derivationPath)
	}
}

extension EntityDerivationPathProtocol {
	public init(derivationPath: String) throws {
		try self.init(fullPath: .init(string: derivationPath))
	}
}

extension HD.Path.Full {
	public var children: [HD.Path.Component.Child] {
		components.dropFirst().compactMap(\.asChild)
	}

	public subscript(index: Int) -> HD.Path.Component.Child {
		children[index]
	}
}

// MARK: - EntityDerivationPathComponentIndex
/// index after having removed `m` as path component, i.e. letting `purpose` have index 0.
public enum EntityDerivationPathComponentIndex: Int, Sendable, Hashable, CaseIterable {
	case purposeIndex
	case coinTypeIndex
	case networkIndex
	case entityKindIndex
	case keyKindIndex
	case entityIndexIndex
}

extension EntityDerivationPathProtocol {
	/// includes counting `m` as a path component
	static var expectedComponentCount: Int {
		// children + component: `m`
		EntityDerivationPathComponentIndex.allCases.count + 1
	}

	@discardableResult
	static func validate(hdPath: HD.Path.Full) throws -> HD.Path.Full {
		let components = hdPath.components
		guard components.count == Self.expectedComponentCount else {
			throw InvalidDerivationPathForEntity.invalidComponentCount(got: components.count, expected: expectedComponentCount)
		}

		guard components.first!.isRoot else {
			throw InvalidDerivationPathForEntity.invalidFirstComponentNotRoot
		}
		let children = hdPath.children
		guard children.count == (Self.expectedComponentCount - 1) else {
			throw InvalidDerivationPathForEntity.multipleRootsFound
		}

		let nonHardenedComponent = children.first(where: { !$0.isHardened })
		if let nonHardenedComponent {
			throw InvalidDerivationPathForEntity.foundNonHardenedComponent(atDepth: nonHardenedComponent.depth.asExplicit)
		}
		assert(children.allSatisfy(\.isHardened))

		guard hdPath[.purposeIndex] == .bip44Purpose else {
			throw InvalidDerivationPathForEntity.secondComponentIsNotBIP44
		}
		guard hdPath[.coinTypeIndex] == .coinType else {
			throw InvalidDerivationPathForEntity.invalidCoinType(got: children[EntityDerivationPathComponentIndex.coinTypeIndex.rawValue].nonHardenedValue)
		}

		guard hdPath[.networkIndex] <= UInt8.max else {
			throw InvalidDerivationPathForEntity.invalidNetworkIDValueTooLarge
		}

		guard hdPath[.entityKindIndex] == Entity.entityKind.derivationPathComponentNonHardenedValue else {
			throw InvalidDerivationPathForEntity.invalidEntityType(got: children[EntityDerivationPathComponentIndex.entityKindIndex.rawValue].nonHardenedValue)
		}

		let validKeyTypeValues = KeyKind.allCases.map(\.rawValue)
		guard validKeyTypeValues.contains(hdPath[.keyKindIndex]) else {
			throw InvalidDerivationPathForEntity.invalidKeyType(got: children[EntityDerivationPathComponentIndex.keyKindIndex.rawValue].nonHardenedValue, expectedAnyOf: validKeyTypeValues)
		}

		// no validation for entity index... index.

		// Valid!
		return hdPath
	}
}

// MARK: - InvalidDerivationPathForEntity
public enum InvalidDerivationPathForEntity:
	Swift.Error,
	Sendable,
	Hashable,
	Codable,
	CustomStringConvertible,
	CustomDumpStringConvertible
{
	case invalidComponentCount(got: Int, expected: Int)
	case invalidFirstComponentNotRoot
	case foundNonHardenedComponent(atDepth: HD.Path.Component.Child.Depth.Value?)
	case multipleRootsFound
	case secondComponentIsNotBIP44
	case invalidNetworkIDValueTooLarge
	case invalidCoinType(got: HD.Path.Component.Child.Value)
	case invalidEntityType(got: HD.Path.Component.Child.Value)
	case invalidKeyType(got: HD.Path.Component.Child.Value, expectedAnyOf: [HD.Path.Component.Child.Value])
}

extension HD.Path.Component.Child.Depth {
	var asExplicit: Value? {
		switch self {
		case let .explicit(explicit):
			return explicit
		case .inferred:
			return nil
		}
	}
}

extension InvalidDerivationPathForEntity {
	public var customDumpDescription: String {
		switch self {
		case let .invalidComponentCount(expected, unexpected): return "InvalidDerivationPathForEntity.invalidComponentCount(expected: \(expected), butGot: \(unexpected))"
		case .invalidFirstComponentNotRoot: return "InvalidDerivationPathForEntity.invalidFirstComponentNotRoot"
		case let .foundNonHardenedComponent(maybeDepth): return "InvalidDerivationPathForEntity.foundNonHardenedComponent(atDepth: \(String(describing: maybeDepth))"
		case .multipleRootsFound: return "InvalidDerivationPathForEntity.multipleRootsFound"
		case .secondComponentIsNotBIP44: return "InvalidDerivationPathForEntity.secondComponentIsNotBIP44"
		case .invalidNetworkIDValueTooLarge: return "InvalidDerivationPathForEntity.invalidNetworkIDValueTooLarge"
		case let .invalidCoinType(unexpected): return "InvalidDerivationPathForEntity.invalidCoinType(\(unexpected))"
		case let .invalidEntityType(unexpected): return "InvalidDerivationPathForEntity.invalidEntityType(\(unexpected))"
		case let .invalidKeyType(expected, unexpected): return "InvalidDerivationPathForEntity.invalidKeyType(expectedAnyOf: \(expected), butGot: \(unexpected))"
		}
	}

	public var description: String {
		switch self {
		case let .invalidComponentCount(expected, unexpected): return "InvalidDerivationPathForEntity.invalidComponentCount(expected: \(expected), butGot: \(unexpected))"
		case .invalidFirstComponentNotRoot: return "InvalidDerivationPathForEntity.invalidFirstComponentNotRoot"
		case let .foundNonHardenedComponent(maybeDepth): return "InvalidDerivationPathForEntity.foundNonHardenedComponent(atDepth: \(String(describing: maybeDepth))"
		case .multipleRootsFound: return "InvalidDerivationPathForEntity.multipleRootsFound"
		case .secondComponentIsNotBIP44: return "InvalidDerivationPathForEntity.secondComponentIsNotBIP44"
		case .invalidNetworkIDValueTooLarge: return "InvalidDerivationPathForEntity.invalidNetworkIDValueTooLarge"
		case let .invalidCoinType(unexpected): return "InvalidDerivationPathForEntity.invalidCoinType(\(unexpected))"
		case let .invalidEntityType(unexpected): return "InvalidDerivationPathForEntity.invalidEntityType(\(unexpected))"
		case let .invalidKeyType(expected, unexpected): return "InvalidDerivationPathForEntity.invalidKeyType(expectedAnyOf: \(expected), butGot: \(unexpected))"
		}
	}
}

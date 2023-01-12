import Cryptography
import EngineToolkit
import Prelude

// MARK: - CannotCreateDerivationPathEntityIndexIsOutOfBound
struct CannotCreateDerivationPathEntityIndexIsOutOfBound: Swift.Error {}

public extension HD.Path.Component.Child {
	static let bip44Purpose: Self = .init(nonHardenedValue: 44, isHardened: true)

	static let coinType: Self = .init(nonHardenedValue: 1022, isHardened: true)

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
	static let getID: Self = .init(nonHardenedValue: 365, isHardened: true)
}

public extension HD.Path.Full {
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
	static let getID: Self = {
		try! Self(
			children: [
				.bip44Purpose,
				.coinType,
				.getID,
			],
			onlyPublic: false
		)
	}()

	static func identity(
		networkID: NetworkID,
		index: Int,
		keyKind: KeyKind
	) throws -> Self {
		try .defaultForEntity(
			networkID: networkID,
			entityKind: .identity,
			index: index,
			keyKind: keyKind
		)
	}

	static func account(
		networkID: NetworkID,
		index: Int,
		keyKind: KeyKind
	) throws -> Self {
		try .defaultForEntity(
			networkID: networkID,
			entityKind: .account,
			index: index,
			keyKind: keyKind
		)
	}

	static func defaultForEntity(
		networkID: NetworkID,
		entityKind: EntityKind,
		index unboundIndex: Int,
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
				.init(nonHardenedValue: index, isHardened: isHardened),
				.init(nonHardenedValue: keyKind.derivationPathComponentNonHardenedValue, isHardened: isHardened),
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
		index: Int,
		keyKind: KeyKind
	) throws

	init(
		fullPath: HD.Path.Full
	) throws
}

public extension EntityDerivationPathProtocol {
	var derivationPath: String { fullPath.toString() }
	static var derivationScheme: DerivationScheme { .slip10 }
	static var purpose: DerivationPurpose { .publicKeyForAddressOfEntity(type: Entity.self) }
}

public extension DerivationPathProtocol where Self: Encodable {
	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(derivationPath)
	}
}

public extension DerivationPathProtocol where Self: Decodable {
	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let derivationPath = try container.decode(String.self)
		try self.init(derivationPath: derivationPath)
	}
}

public extension EntityDerivationPathProtocol {
	init(derivationPath: String) throws {
		try self.init(fullPath: .init(string: derivationPath))
	}
}

// MARK: - AccountHierarchicalDeterministicDerivationPath
/// The **default** derivation path used to derive `Account` keys for signing of
/// transactions or for signing authentication, at a certain account index (`ENTITY_INDEX`)
/// and **unique per network** (`NETWORK_ID`) as per [CAP-26][cap26].
///
/// Note that users can chose to use custom derivation path instead of this default
/// one when deriving keys for accounts.
///
/// The format is:
///
///     `m/44'/1022'/<NETWORK_ID>'/525'/<ENTITY_INDEX>'/<KEY_TYPE>'`
///
/// Where `'` denotes hardened path, which is **required** as per [SLIP-10][slip10],
/// where `525` is ASCII sum of `"ACCOUNT"`, i.e. `"ACCOUNT".map{ $0.asciiValue! }.reduce(0, +)`
///
/// [cap26]: https://radixdlt.atlassian.net/l/cp/UNaBAGUC
/// [slip10]: https://github.com/satoshilabs/slips/blob/master/slip-0010.md
///
public struct AccountHierarchicalDeterministicDerivationPath:
	EntityDerivationPathProtocol,
	Sendable,
	Hashable,
	Codable,
	Identifiable,
	CustomStringConvertible,
	CustomDumpStringConvertible
{
	public typealias Entity = OnNetwork.Account
	public let fullPath: HD.Path.Full

	public init(
		networkID: NetworkID,
		index: Int,
		keyKind: KeyKind
	) throws {
		try self.init(fullPath: HD.Path.Full.account(
			networkID: networkID,
			index: index,
			keyKind: keyKind
		))
	}

	public init(fullPath: HD.Path.Full) throws {
		self.fullPath = try Self.validate(hdPath: fullPath)
	}
}

extension EntityDerivationPathProtocol {
	static var expectedComponentCount: Int { 7 }
	@discardableResult
	static func validate(hdPath: HD.Path.Full) throws -> HD.Path.Full {
		let components = hdPath.components
		guard components.count == Self.expectedComponentCount else {
			throw InvalidDerivationPathForEntity.invalidComponentCount(expected: expectedComponentCount, gotGot: components.count)
		}

		guard components.first!.isRoot else {
			throw InvalidDerivationPathForEntity.invalidFirstComponentNotRoot
		}
		let children = components.dropFirst().compactMap(\.asChild)
		guard children.count == (Self.expectedComponentCount - 1) else {
			throw InvalidDerivationPathForEntity.multipleRootsFound
		}

		let nonHardenedComponent = children.first(where: { !$0.isHardened })
		if let nonHardenedComponent {
			throw InvalidDerivationPathForEntity.foundNonHardenedComponent(atDepth: nonHardenedComponent.depth.asExplicit)
		}
		assert(children.allSatisfy(\.isHardened))

		guard children[0] == .bip44Purpose else {
			throw InvalidDerivationPathForEntity.secondComponentIsNotBIP44
		}
		guard children[1] == .coinType else {
			throw InvalidDerivationPathForEntity.invalidCoinType(got: children[1].nonHardenedValue)
		}

		guard children[2].nonHardenedValue <= UInt8.max else {
			throw InvalidDerivationPathForEntity.invalidNetworkIDValueTooLarge
		}

		guard children[3].nonHardenedValue == Entity.entityKind.derivationPathComponentNonHardenedValue else {
			throw InvalidDerivationPathForEntity.invalidEntityType(got: children[3].nonHardenedValue)
		}
		// No validation needed for `index`
		let validKeyTypeValues = KeyKind.allCases.map(\.rawValue)
		guard validKeyTypeValues.contains(children[5].nonHardenedValue) else {
			throw InvalidDerivationPathForEntity.invalidKeyType(expectedAnyOf: validKeyTypeValues, butGot: children[5].nonHardenedValue)
		}

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
	case invalidComponentCount(expected: Int, gotGot: Int)
	case invalidFirstComponentNotRoot
	case foundNonHardenedComponent(atDepth: HD.Path.Component.Child.Depth.Value?)
	case multipleRootsFound
	case secondComponentIsNotBIP44
	case invalidNetworkIDValueTooLarge
	case invalidCoinType(got: HD.Path.Component.Child.Value)
	case invalidEntityType(got: HD.Path.Component.Child.Value)
	case invalidKeyType(expectedAnyOf: [HD.Path.Component.Child.Value], butGot: HD.Path.Component.Child.Value)
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

public extension InvalidDerivationPathForEntity {
	var customDumpDescription: String {
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

	var description: String {
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

public extension AccountHierarchicalDeterministicDerivationPath {
	var customDumpDescription: String {
		"AccountHierarchicalDeterministicDerivationPath(\(derivationPath))"
	}

	var description: String {
		"""
		AccountHierarchicalDeterministicDerivationPath: \(derivationPath),
		"""
	}
}

public extension AccountHierarchicalDeterministicDerivationPath {
	/// Wraps this specific type of derivation path to the shared
	/// nominal type `DerivationPath` (enum)
	func wrapAsDerivationPath() -> DerivationPath {
		.accountPath(self)
	}

	/// Tries to unwraps the nominal type `DerivationPath` (enum)
	/// into this specific type.
	static func unwrap(derivationPath: DerivationPath) -> Self? {
		switch derivationPath {
		case let .accountPath(path): return path
		default: return nil
		}
	}
}

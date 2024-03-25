

public typealias Address = SpecificAddress<GeneralEntityType>

extension Address {
	public func entityType() -> EntityType {
		sargon()
	}

	public init(address: String, decodedKind: EntityType) {
		sargon()
	}

	public func bytes() -> [UInt8] {
		sargon()
	}
}

public typealias PackageAddress = SpecificAddress<PackageEntityType>
public typealias ResourceAddress = SpecificAddress<ResourceEntityType>

extension ResourceAddress {
	public func isXRD(on networkID: NetworkID) -> Bool {
		Self.xrd(on: networkID) == self
	}
}

public typealias ComponentAddress = SpecificAddress<ComponentEntityType>
public typealias AccountAddress = SpecificAddress<AccountEntityType>
public typealias IdentityAddress = SpecificAddress<IdentityEntityType>
public typealias AccessControllerAddress = SpecificAddress<AccessControllerEntityType>
public typealias VaultAddress = SpecificAddress<VaultEntityType>
public typealias ValidatorAddress = SpecificAddress<ValidatorEntityType>
public typealias PoolAddress = SpecificAddress<ResourcePoolEntityType>

// MARK: - EntityType + CaseIterable
extension EntityType: CaseIterable {
	public static var allCases: [EntityType] {
		[
			.globalAccessController,
			.globalAccount,
			.globalConsensusManager,
			.globalFungibleResourceManager,
			.globalGenericComponent,
			.globalIdentity,
			.globalNonFungibleResourceManager,
			.globalPackage,
			.globalValidator,
			.globalVirtualEd25519Account,
			.globalVirtualEd25519Identity,
			.globalVirtualSecp256k1Account,
			.globalVirtualSecp256k1Identity,
			.internalFungibleVault,
			.internalGenericComponent,
			.internalKeyValueStore,
			.internalNonFungibleVault,
			.globalOneResourcePool,
			.globalTwoResourcePool,
			.globalMultiResourcePool,
		]
	}
}

// MARK: - GeneralEntityType
public enum GeneralEntityType: SpecificEntityType {
	public static let addressSpace: Set<EntityType> = Set(EntityType.allCases)
}

// MARK: - ResourceEntityType
public enum ResourceEntityType: SpecificEntityType {
	public static let addressSpace: Set<EntityType> = [.globalFungibleResourceManager, .globalNonFungibleResourceManager]
}

// MARK: - PackageEntityType
public enum PackageEntityType: SpecificEntityType {
	public static let addressSpace: Set<EntityType> = [.globalPackage]
}

// MARK: - EntityType
public enum EntityType: DummySargon {
	case globalPackage
	case globalFungibleResourceManager
	case globalNonFungibleResourceManager
	case globalConsensusManager
	case globalValidator
	case globalAccessController
	case globalAccount
	case globalIdentity
	case globalGenericComponent
	case globalVirtualSecp256k1Account
	case globalVirtualEd25519Account
	case globalVirtualSecp256k1Identity
	case globalVirtualEd25519Identity
	case globalOneResourcePool
	case globalTwoResourcePool
	case globalMultiResourcePool
	case globalTransactionTracker
	case internalFungibleVault
	case internalNonFungibleVault
	case internalGenericComponent
	case internalKeyValueStore

	public var isResourcePool: Bool {
		sargon()
	}
}

// MARK: - ComponentEntityType
public enum ComponentEntityType: SpecificEntityType {
	public static let addressSpace: Set<EntityType> = AccountEntityType.addressSpace
		.union(IdentityEntityType.addressSpace)
		.union(AccessControllerEntityType.addressSpace)
		.union(VaultEntityType.addressSpace)
		.union(ValidatorEntityType.addressSpace)
}

// MARK: - AccountEntityType
public enum AccountEntityType: SpecificEntityType {
	public static let addressSpace: Set<EntityType> = [.globalAccount, .globalVirtualEd25519Account, .globalVirtualSecp256k1Account]
}

// MARK: - IdentityEntityType
public enum IdentityEntityType: SpecificEntityType {
	public static let addressSpace: Set<EntityType> = [.globalIdentity, .globalVirtualEd25519Identity, .globalVirtualSecp256k1Identity]
}

// MARK: - AccessControllerEntityType
public enum AccessControllerEntityType: SpecificEntityType {
	public static let addressSpace: Set<EntityType> = [.globalAccessController]
}

// MARK: - VaultEntityType
public enum VaultEntityType: SpecificEntityType {
	public static let addressSpace: Set<EntityType> = [.internalFungibleVault, .internalNonFungibleVault]
}

// MARK: - ValidatorEntityType
public enum ValidatorEntityType: SpecificEntityType {
	public static let addressSpace: Set<EntityType> = [.globalValidator]
}

// MARK: - ResourcePoolEntityType
public enum ResourcePoolEntityType: SpecificEntityType {
	public static let addressSpace: Set<EntityType> = [.globalOneResourcePool, .globalTwoResourcePool, .globalMultiResourcePool]
}

// MARK: - SpecificEntityType
public protocol SpecificEntityType: Sendable {
	/// The valid address space that can match a given kind of addresses
	static var addressSpace: Set<EntityType> { get }
}

// MARK: - SpecificAddress
public struct SpecificAddress<Kind: SpecificEntityType>: Sendable, Hashable, Identifiable {
	public struct InvalidAddress: Error, LocalizedError {
		let decodedKind: EntityType
		let addressSpace: Set<EntityType>

		public var errorDescription: String? {
			"Decoded EntityType -> \(decodedKind), not found in the expected address space \(addressSpace)"
		}
	}

	public func asStr() -> String {
		sargon()
	}

	public var id: String {
		address
	}

	public let address: String

	public func addressString() -> String {
		address
	}

	public let decodedKind: EntityType

	public func bytes() -> Data {
		sargon()
	}

	public init(address: String) throws {
		sargon()
	}

	public init(address: String, decodedKind: EntityType) {
		self.address = address
		self.decodedKind = decodedKind
	}

	public init(validatingAddress address: String) throws {
		sargon()
	}

	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.address == rhs.address
	}
}

// MARK: Codable
extension SpecificAddress: Codable {
	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(address)
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		try self.init(validatingAddress: container.decode(String.self))
	}
}

// MARK: CustomStringConvertible
extension SpecificAddress: CustomStringConvertible {
	public var description: String {
		address
	}
}

extension SpecificAddress {
	public var asGeneral: Address {
		.init(address: address, decodedKind: decodedKind)
	}
}

extension AccountAddress {
	public var asComponentAddress: ComponentAddress {
		.init(address: address, decodedKind: decodedKind)
	}
}

extension Address {
	public func asSpecific<T>() throws -> SpecificAddress<T> {
		try .init(validatingAddress: addressString())
	}
}

extension [Address] {
	public func asSpecific<T>() throws -> [SpecificAddress<T>] {
		try map { try $0.asSpecific() }
	}
}

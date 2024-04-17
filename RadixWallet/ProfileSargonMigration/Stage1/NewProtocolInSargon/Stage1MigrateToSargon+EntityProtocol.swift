import Sargon

// MARK: - EntityBaseProtocol
public protocol EntityBaseProtocol {
	typealias Flags = EntityFlags

	/// The ID of the network this entity exists on.
	var networkID: Sargon.NetworkID { get }

	/// Security state of this entity, either `secured` or not (controlled by a single FactorInstance)
	var securityState: Sargon.EntitySecurityState { get }

	/// A required non empty display name, used by presentation layer and sent to Dapps when requested.
	var displayName: DisplayName { get }

	/// Flags that are currently set on entity.
	var flags: Flags { get }
}

extension EntityBaseProtocol {
	public var virtualHierarchicalDeterministicFactorInstances: Set<Sargon.HierarchicalDeterministicFactorInstance> {
//		var factorInstances = Set<HierarchicalDeterministicFactorInstance>()
//		switch securityState {
//		case let .unsecured(unsecuredEntityControl):
//			factorInstances.insert(unsecuredEntityControl.transactionSigning)
//			if let authSigning = unsecuredEntityControl.authenticationSigning {
//				factorInstances.insert(authSigning)
//			}
//			return factorInstances
//		}
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public var hasAuthenticationSigningKey: Bool {
		switch securityState {
		case let .unsecured(unsecuredEntityControl):
			unsecuredEntityControl.authenticationSigning != nil
		}
	}
}

// MARK: - EntityProtocol
/// An `Account` or a `Persona`
public protocol EntityProtocol: EntityBaseProtocol, Sendable, Equatable, Identifiable where ID == EntityAddress {
	/// The type of address of entity.
	associatedtype EntityAddress: AddressProtocol & Hashable
	associatedtype ExtraProperties: Sendable

	static var entityKind: Sargon.EntityKind { get }

	static func deriveVirtualAddress(
		networkID: Sargon.NetworkID,
		factorInstance: Sargon.HierarchicalDeterministicFactorInstance
	) throws -> EntityAddress

	/// Security state of this entity, either `secured` or not (controlled by a single FactorInstance)
	var securityState: Sargon.EntitySecurityState { get set }

	/// The globally unique and identifiable Radix component address of this entity. Can be used as
	/// a stable ID. Cryptographically derived from a seeding public key which typically was created by
	/// the `DeviceFactorSource`
	var address: EntityAddress { get }

	func cast<Entity: EntityProtocol>() throws -> Entity

	init(
		networkID: NetworkID,
		address: EntityAddress,
		securityState: EntitySecurityState,
		displayName: NonEmpty<String>,
		extraProperties: ExtraProperties
	)
}

extension EntityProtocol {
	public var kind: EntityKind { Self.entityKind }

	public init(
		networkID: NetworkID,
		address: EntityAddress,
		factorInstance: Sargon.HierarchicalDeterministicFactorInstance,
		displayName: DisplayName,
		extraProperties: ExtraProperties
	) {
//		self.init(
//			networkID: networkID,
//			address: address,
//			securityState: .unsecured(.init(transactionSigning: factorInstance)),
//			displayName: displayName,
//			extraProperties: extraProperties
//		)
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public init(
		networkID: NetworkID,
		factorInstance: HierarchicalDeterministicFactorInstance,
		displayName: NonEmpty<String>,
		extraProperties: ExtraProperties
	) throws {
//		let address = try Self.deriveVirtualAddress(networkID: networkID, factorInstance: factorInstance)
//		self.init(
//			networkID: networkID,
//			address: address,
//			factorInstance: factorInstance,
//			displayName: displayName,
//			extraProperties: extraProperties
//		)
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}

// MARK: - EntityKindMismatchDiscrepancy
struct EntityKindMismatchDiscrepancy: Swift.Error {}
extension EntityProtocol {
	public func cast<Entity: EntityProtocol>() throws -> Entity {
		try self.cast(to: Entity.self)
	}

	public func cast<Entity: EntityProtocol>(
		to entityType: Entity.Type
	) throws -> Entity {
		guard
			let entity = self as? Entity
		else {
			let errorMsg = "Critical error, entity kind mismatch discrepancy"
			loggerGlobal.critical(.init(stringLiteral: errorMsg))
			assertionFailure(errorMsg)
			throw EntityKindMismatchDiscrepancy()
		}
		return entity
	}
}

extension EntityBaseProtocol {
	public var isHidden: Bool {
		flags.contains(.deletedByUser)
	}
}

extension EntityProtocol {
	public var deviceFactorSourceID: FactorSourceIDFromHash? {
//		switch self.securityState {
//		case let .unsecured(control):
//			let factorSourceID = control.transactionSigning.factorSourceID
//			guard factorSourceID.kind == .device else {
//				return nil
//			}
//
//			return factorSourceID
//		}
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}

// MARK: - Account + EntityProtocol
extension Account: EntityProtocol {
	public struct ExtraProperties: Sendable {
		public var appearanceID: AppearanceID
		public let onLedgerSettings: OnLedgerSettings

		public init(
			appearanceID: AppearanceID,
			onLedgerSettings: OnLedgerSettings = .default
		) {
			self.appearanceID = appearanceID
			self.onLedgerSettings = onLedgerSettings
		}
	}

	public init(
		networkID: NetworkID,
		address: AccountAddress,
		securityState: EntitySecurityState,
		displayName: NonEmptyString,
		extraProperties: ExtraProperties
	) {
		self.init(
			networkId: networkID,
			address: address,
			displayName: DisplayName(nonEmpty: displayName),
			securityState: securityState,
			appearanceId: extraProperties.appearanceID,
			flags: [],
			onLedgerSettings: extraProperties.onLedgerSettings
		)
	}

	public static var entityKind: EntityKind {
		.account
	}

	public static func deriveVirtualAddress(
		networkID: NetworkID,
		factorInstance: HierarchicalDeterministicFactorInstance
	) throws -> AccountAddress {
		AccountAddress(publicKey: factorInstance.publicKey.publicKey, networkID: networkID)
	}

	public typealias EntityAddress = AccountAddress
}

// MARK: - Persona + EntityProtocol
extension Persona: EntityProtocol {
	public typealias EntityAddress = IdentityAddress

	/// Ephemeral, only used as arg passed to init.
	public struct ExtraProperties: Sendable, Hashable {
		public var personaData: PersonaData
		public init(personaData: PersonaData) {
			self.personaData = personaData
		}
	}

	public init(
		networkID: NetworkID,
		address: IdentityAddress,
		securityState: EntitySecurityState,
		displayName: NonEmptyString,
		extraProperties: ExtraProperties
	) {
		self.init(
			networkId: networkID,
			address: address,
			displayName: DisplayName(nonEmpty: displayName),
			securityState: securityState,
			flags: [],
			personaData: extraProperties.personaData
		)
	}

	public static var entityKind: EntityKind {
		.account
	}

	public static func deriveVirtualAddress(
		networkID: NetworkID,
		factorInstance: HierarchicalDeterministicFactorInstance
	) throws -> IdentityAddress {
		IdentityAddress(publicKey: factorInstance.publicKey.publicKey, networkID: networkID)
	}
}

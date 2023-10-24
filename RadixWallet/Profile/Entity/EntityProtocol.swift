import EngineToolkit

// MARK: - EntityBaseProtocol
public protocol EntityBaseProtocol {
	/// The ID of the network this entity exists on.
	var networkID: NetworkID { get }

	/// The index of the account, being a counter, e.g. if you already have two accounts and create a third,
	/// the index of the new account will be 2 (and the indices of the first is 0 and second is 1).
	var index: HD.Path.Component.Child.Value { get }

	/// Security state of this entity, either `secured` or not (controlled by a single FactorInstance)
	var securityState: EntitySecurityState { get }

	/// A required non empty display name, used by presentation layer and sent to Dapps when requested.
	var displayName: NonEmpty<String> { get }

	/// Flags that are currently set on entity.
	var flags: Set<EntityFlag> { get }
}

extension EntityBaseProtocol {
	public var virtualHierarchicalDeterministicFactorInstances: Set<HierarchicalDeterministicFactorInstance> {
		var factorInstances = Set<HierarchicalDeterministicFactorInstance>()
		switch securityState {
		case let .unsecured(unsecuredEntityControl):
			factorInstances.insert(unsecuredEntityControl.transactionSigning)
			if let authSigning = unsecuredEntityControl.authenticationSigning {
				factorInstances.insert(authSigning)
			}
			return factorInstances
		}
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

	static var entityKind: EntityKind { get }

	static func deriveVirtualAddress(
		networkID: NetworkID,
		factorInstance: HierarchicalDeterministicFactorInstance
	) throws -> EntityAddress

	/// Security state of this entity, either `secured` or not (controlled by a single FactorInstance)
	var securityState: EntitySecurityState { get set }

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
	/// A stable and globally unique identifier for this account.
	public var id: ID { address }

	public var kind: EntityKind { Self.entityKind }

	public init(
		networkID: NetworkID,
		index: HD.Path.Component.Child.Value,
		address: EntityAddress,
		factorInstance: HierarchicalDeterministicFactorInstance,
		displayName: NonEmpty<String>,
		extraProperties: ExtraProperties
	) {
		self.init(
			networkID: networkID,
			address: address,
			securityState: .unsecured(.init(entityIndex: index, transactionSigning: factorInstance)),
			displayName: displayName,
			extraProperties: extraProperties
		)
	}

	public init(
		networkID: NetworkID,
		index: HD.Path.Component.Child.Value,
		factorInstance: HierarchicalDeterministicFactorInstance,
		displayName: NonEmpty<String>,
		extraProperties: ExtraProperties
	) throws {
		let address = try Self.deriveVirtualAddress(networkID: networkID, factorInstance: factorInstance)
		self.init(
			networkID: networkID,
			index: index,
			address: address,
			factorInstance: factorInstance,
			displayName: displayName,
			extraProperties: extraProperties
		)
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

import Cryptography
import EngineToolkitModels
import Prelude

// MARK: - EntityProtocol
/// An `Account` or a `Persona`
public protocol EntityProtocol: Sendable, Equatable {
	/// The type of address of entity.
	associatedtype EntityAddress: AddressKindProtocol & Hashable

	static var entityKind: EntityKind { get }

	static func deriveAddress(
		networkID: NetworkID,
		publicKey: SLIP10.PublicKey
	) throws -> EntityAddress

	/// The ID of the network this entity exists on.
	var networkID: NetworkID { get }

	/// The globally unique and identifiable Radix component address of this entity. Can be used as
	/// a stable ID. Cryptographically derived from a seeding public key which typically was created by
	/// the `DeviceFactorSource`
	var address: EntityAddress { get }

	/// Security state of this entity, either `secured` or not (controlled by a single FactorInstance)
	var securityState: EntitySecurityState { get set }

	/// A required non empty display name, used by presentation layer and sent to Dapps when requested.
	var displayName: NonEmpty<String> { get }

	func cast<Entity: EntityProtocol>() throws -> Entity
}

extension EntityProtocol {
	public var kind: EntityKind { Self.entityKind }
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

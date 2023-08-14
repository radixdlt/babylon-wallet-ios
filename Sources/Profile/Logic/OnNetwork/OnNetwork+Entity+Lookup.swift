import Cryptography
import EngineKit
import Prelude

// MARK: - NoInstance
internal struct NoInstance: Swift.Error {}

// MARK: - AccountIndexOutOfBounds
struct AccountIndexOutOfBounds: Swift.Error {}

// MARK: - PersonaIndexOutOfBounds
struct PersonaIndexOutOfBounds: Swift.Error {}

// MARK: - NoEntityFoundMatchingCriteria
struct NoEntityFoundMatchingCriteria: Swift.Error {}

extension Profile {
	public func entity(
		networkID: NetworkID,
		kind: EntityKind,
		entityIndex: Int
	) throws -> any EntityProtocol {
		let network = try network(id: networkID)
		switch kind {
		case .account:
			guard entityIndex < network.accounts.count else {
				throw AccountIndexOutOfBounds()
			}
			return network.accounts[entityIndex]
		case .identity:
			guard entityIndex < network.personas.count else {
				throw PersonaIndexOutOfBounds()
			}
			return network.personas[entityIndex]
		}
	}

	public func entity<Entity: EntityProtocol>(
		networkID: NetworkID,
		entityType: Entity.Type,
		entityIndex: Int
	) throws -> Entity {
		guard let entity = try entity(networkID: networkID, kind: entityType.entityKind, entityIndex: entityIndex) as? Entity else {
			throw IncorrectEntityType()
		}
		return entity
	}

	public func entity(
		networkID: NetworkID,
		address: AddressProtocol
	) throws -> any EntityProtocol {
		try network(id: networkID).entity(address: address)
	}
}

// MARK: - IncorrectEntityType
public struct IncorrectEntityType: Swift.Error {}

extension Profile.Network {
	public func entity<Entity: EntityProtocol>(
		address: Entity.EntityAddress
	) throws -> Entity {
		try entity(type: Entity.self, address: address)
	}

	public func entity<Entity: EntityProtocol>(
		type: Entity.Type,
		address: Entity.EntityAddress
	) throws -> Entity {
		guard let entity = try self.entity(address: address) as? Entity else {
			throw IncorrectEntityType()
		}
		return entity
	}

	public func entity(
		address: AddressProtocol
	) throws -> any EntityProtocol {
		if let account = accounts.first(where: { $0.address.address == address.address }) {
			return account
		} else if let persona = personas.first(where: { $0.address.address == address.address }) {
			return persona
		} else {
			throw NoEntityFoundMatchingCriteria()
		}
	}
}

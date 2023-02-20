import Cryptography
import EngineToolkitModels
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
		let onNetwork = try onNetwork(id: networkID)
		switch kind {
		case .account:
			guard entityIndex < onNetwork.accounts.count else {
				throw AccountIndexOutOfBounds()
			}
			return onNetwork.accounts[entityIndex]
		case .identity:
			guard entityIndex < onNetwork.personas.count else {
				throw PersonaIndexOutOfBounds()
			}
			return onNetwork.personas[entityIndex]
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

	public struct IncorrectEntityType: Swift.Error {}

	public func entity(
		networkID: NetworkID,
		address: ProfileModels.AddressProtocol
	) throws -> any EntityProtocol {
		let onNetwork = try onNetwork(id: networkID)
		if let account = onNetwork.accounts.first(where: { $0.address.address == address.address }) {
			return account
		} else if let persona = onNetwork.personas.first(where: { $0.address.address == address.address }) {
			return persona
		} else {
			throw NoEntityFoundMatchingCriteria()
		}
	}
}

// MARK: - NoEntityFoundMatchingCriteria
struct NoEntityFoundMatchingCriteria: Swift.Error {}

// MARK: - IncorrectEntityType
struct IncorrectEntityType: Swift.Error {}

extension ProfileNetwork {
	func entity<Entity: EntityProtocol>(
		address: Entity.EntityAddress
	) throws -> Entity {
		try entity(type: Entity.self, address: address)
	}

	func entity<Entity: EntityProtocol>(
		type: Entity.Type,
		address: Entity.EntityAddress
	) throws -> Entity {
		guard let entity = try self.entity(address: address) as? Entity else {
			throw IncorrectEntityType()
		}
		return entity
	}

	func entity(
		address: any AddressProtocol
	) throws -> any EntityProtocol {
		if let account = getAccounts().first(where: { $0.address.address == address.address }) {
			return account
		} else if let persona = getPersonas().first(where: { $0.address.address == address.address }) {
			return persona
		} else {
			throw NoEntityFoundMatchingCriteria()
		}
	}
}

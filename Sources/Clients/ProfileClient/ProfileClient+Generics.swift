import ClientPrelude
import ProfileModels

extension ProfileClient {
	public func createNewUnsavedVirtualEntity<Entity: EntityProtocol & Sendable>(
		request: CreateVirtualEntityRequest
	) async throws -> Entity {
		guard Entity.entityKind == request.entityKind else {
			throw DiscrepancyBetweenSpecifiedEntityKindInRequestAndGenericTypeArgument()
		}
		let anyEntity = try await self.createUnsavedVirtualEntity(request)
		guard let entity = anyEntity as? Entity else {
			throw DiscrepancyBetweenSpecifiedEntityKindInRequestAndGenericTypeArgument()
		}
		return entity
	}

	public func saveNewEntity<Entity: EntityProtocol>(_ entity: Entity) async throws {
		switch entity.kind {
		case .account:
			guard let account = entity as? OnNetwork.Account else {
				throw DiscrepancyBetweenSpecifiedEntityKindInRequestAndGenericTypeArgument()
			}
			try await self.addAccount(account)
		case .identity:
			guard let persona = entity as? OnNetwork.Persona else {
				throw DiscrepancyBetweenSpecifiedEntityKindInRequestAndGenericTypeArgument()
			}
			try await self.addPersona(persona)
		}
	}
}

// MARK: - DiscrepancyBetweenSpecifiedEntityKindInRequestAndGenericTypeArgument
struct DiscrepancyBetweenSpecifiedEntityKindInRequestAndGenericTypeArgument: Swift.Error {}

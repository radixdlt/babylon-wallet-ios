import FeaturePrelude
import ProfileClient

// MARK: - CreationOfEntity
public struct CreationOfEntity<Entity: EntityProtocol>: Sendable, ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.profileClient) var profileClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
	}

	func core(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.appeared)):
			return .run { [networkID = state.networkID, genesisFactorInstanceDerivationStrategy = state.genesisFactorInstanceDerivationStrategy, name = state.name, curve = state.curve] send in
				await send(.internal(.system(.createEntityResult(TaskResult {
					let entityKind = Entity.entityKind
					let request = try CreateVirtualEntityRequest(
						curve: curve,
						networkID: networkID,
						genesisFactorInstanceDerivationStrategy: genesisFactorInstanceDerivationStrategy,
						entityKind: entityKind,
						displayName: name
					)

					let entity: Entity = try await profileClient.createNewUnsavedVirtualEntity(request: request)

					// N.B. if this CreateEntity flow is triggered from NewProfileThenAccount flow
					// (part of onboarding), the ProfileClients live implemntation will hold onto
					// an "ephemeral" profile and this entity gets saved into this ephemeral profile.
					// so at end of NewProfileThenAccount flow we need to "commit" the
					// ephemeral profile so it gets persisted.
					try await profileClient.saveNewEntity(entity)

					return entity
				}
				))))
			}

		case .internal(.system(.createEntityResult(.failure))):
			return .send(.delegate(.createEntityFailed))

		case let .internal(.system(.createEntityResult(.success(entity)))):
			return .run { send in
				await send(.delegate(.createdEntity(entity)))
			}

		case .delegate:
			return .none
		}
	}
}

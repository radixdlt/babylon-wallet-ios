import FeaturePrelude
import OnboardingClient

// MARK: - CreationOfEntity
public struct CreationOfEntity<Entity: EntityProtocol>: Sendable, ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.onboardingClient) var onboardingClient

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

					let entity: Entity = try await onboardingClient.createNewUnsavedVirtualEntity(request: request)

					try await onboardingClient.saveNewVirtualEntity(entity)

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

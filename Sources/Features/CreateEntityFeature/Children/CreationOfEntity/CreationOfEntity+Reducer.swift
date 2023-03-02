import AccountsClient
import FeaturePrelude
import PersonasClient

// MARK: - CreationOfEntity
public struct CreationOfEntity<Entity: EntityProtocol>: Sendable, ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.personasClient) var personasClient

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

					switch entityKind {
					case .account:
						let account = try await accountsClient.createUnsavedVirtualAccount(request: request)
						try await accountsClient.saveVirtualAccount(account)
						return try account.cast()
					case .identity:
						let persona = try await personasClient.createUnsavedVirtualPersona(request: request)
						try await personasClient.saveVirtualPersona(persona)
						return try persona.cast()
					}
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

import FeaturePrelude
import ProfileClient

// MARK: - CreationOfEntity
public struct CreationOfEntity<Entity: EntityProtocol & Equatable & Sendable>: Sendable, ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.profileClient) var profileClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
	}

	func core(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.appeared)):
			return .run { [networkID = state.networkID, genesisFactorSource = state.genesisFactorSource, name = state.name] send in
				await send(.internal(.system(.createEntityResult(TaskResult {
					//                    let getPathRequest = GetDerivationPathForNewEntityRequest(
					//                        networkID: networkID,
					//                        factorSource: genesisFactorSource,
					//                        entityKind: Entity.entityKind,
					//                        keyKind: keyKind
					//                    )
					//                    let derivationPath: Entity.EntityDerivationPath = try await profileClient.getDerivationPathForNewEntity(request: getPathRequest)

					let entityKind = Entity.entityKind
					let entityKindName = entityKind == .account ? L10n.Common.Account.kind : L10n.Common.Persona.kind

					let request = try CreateVirtualEntityRequest(
						networkID: networkID,
						factorSource: genesisFactorSource,
						entityKind: entityKind,
						displayName: name,
						keychainAccessFactorSourcesAuthPrompt: L10n.CreateEntity.CreationOfEntity.biometricsPrompt(entityKindName)
					)

					let entity: Entity = try await profileClient.createNewUnsavedVirtualEntity(request: request)
					// N.B. if this create entity flow is triggered as part of onboarding
					// the ProfileClients live implemntation will hold onto an "ephemeral"
					// profile and this entity gets saved into this ephemeral profile.
					// so at end of NewProfileThenAccount flow we need to "commit" the
					// ephemeral profile so it gets persisted.
					try await profileClient.saveNewEntity(entity)
					return entity
				}
				))))
			}

		case let .internal(.system(.createEntityResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case let .internal(.system(.createEntityResult(.success(entity)))):
			return .run { send in
				await send(.delegate(.createdEntity(entity)))
			}

		case .delegate:
			return .none
		}
	}
}

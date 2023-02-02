import FeaturePrelude
import ProfileClient

private let forceFactorSelection = true

public typealias CreateAccountCoordinator = CreateEntityCoordinator<OnNetwork.Account>
public typealias CreatePersonaCoordinator = CreateEntityCoordinator<OnNetwork.Persona>

// MARK: - CreateEntityCoordinator
public struct CreateEntityCoordinator<
	_Entity: EntityProtocol & Sendable & Equatable
>: Sendable, ReducerProtocol {
	public typealias Entity = _Entity
	@Dependency(\.profileClient) var profileClient
	@Dependency(\.errorQueue) var errorQueue
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.step, action: /Action.self) {
			EmptyReducer()
				.ifCaseLet(/State.Step.step0_nameNewEntity, action: /Action.child .. Action.ChildAction.step0_nameNewEntity) {
					NameNewEntity<Entity>()
				}
				.ifCaseLet(/State.Step.step1_selectGenesisFactorSource, action: /Action.child .. Action.ChildAction.step1_selectGenesisFactorSource) {
					SelectGenesisFactorSource()
				}
				.ifCaseLet(/State.Step.step2_creationOfEntity, action: /Action.child .. Action.ChildAction.step2_creationOfEntity) {
					CreationOfEntity<Entity>()
				}
				.ifCaseLet(/State.Step.step3_completion, action: /Action.child .. Action.ChildAction.step3_completion) {
					NewEntityCompletion<Entity>()
				}
		}
		Reduce(self.core)
	}

	private func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .view(.dismiss):
			precondition(state.config.canBeDismissed)
			return .run { send in
				await send(.delegate(.dismissed))
			}
		case let .child(.step0_nameNewEntity(.delegate(.named(name)))):
			return .run { send in
				await send(.internal(.loadFactorSourcesResult(TaskResult {
					try await profileClient.getFactorSources()
				}, beforeCreatingEntityWithName: name)))
			}

		case let .internal(.loadFactorSourcesResult(.failure(error), _)):
			errorQueue.schedule(error)
			return .none

		case let .internal(.loadFactorSourcesResult(.success(factorSources), specifiedNameForNewEntityToCreate)):
			precondition(!factorSources.factorSources.isEmpty)
			if factorSources.factorSources.count > 1 || forceFactorSelection {
				return goToStep1SelectGenesisFactorSource(
					entityName: specifiedNameForNewEntityToCreate,
					factorSources: factorSources.factorSources,
					state: &state
				)
			} else {
				return goToStep2Creation(
					entityName: specifiedNameForNewEntityToCreate,
					genesisFactorSource: factorSources.factorSources[0].any() as! Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource,
					state: &state
				)
			}

		case .child(.step0_nameNewEntity(.delegate(.dismiss))):
			return .run { send in
				await send(.delegate(.dismissed))
			}

		case let .child(.step1_selectGenesisFactorSource(.delegate(.confirmedFactorSource(factorSource, specifiedNameForNewEntityToCreate)))):
			return goToStep2Creation(
				entityName: specifiedNameForNewEntityToCreate,
				genesisFactorSource: factorSource,
				state: &state
			)

		case let .child(.step2_creationOfEntity(.delegate(.createdEntity(newEntity)))):
			return goToStep3Completion(
				entity: newEntity,
				state: &state
			)

		case let .child(.step3_completion(.delegate(.completed))):
			return .run { send in
				await send(.delegate(.completed))
			}

		default:
			return .none
		}
	}

	private func goToStep1SelectGenesisFactorSource(
		entityName: String,
		factorSources: NonEmpty<IdentifiedArrayOf<FactorSource>>,
		state: inout State
	) -> EffectTask<Action> {
		state.step = .step1_selectGenesisFactorSource(
			.init(
				specifiedNameForNewEntityToCreate: entityName,
				factorSources: factorSources
			)
		)
		return .none
	}

	private func goToStep2Creation(
		entityName: String,
		genesisFactorSource: Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource,
		state: inout State
	) -> EffectTask<Action> {
		state.step = .step2_creationOfEntity(.init(
			networkID: state.config.specificNetworkID,
			name: entityName,
			genesisFactorSource: genesisFactorSource
		))
		return .none
	}

	private func goToStep3Completion(
		entity: Entity,
		state: inout State
	) -> EffectTask<Action> {
		state.step = .step3_completion(.init(
			entity: entity,
			config: state.config
		))
		return .none
	}
}

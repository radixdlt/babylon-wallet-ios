import Cryptography
import FactorSourcesClient
import FeaturePrelude

public typealias CreateAccountCoordinator = CreateEntityCoordinator<OnNetwork.Account>
public typealias CreatePersonaCoordinator = CreateEntityCoordinator<OnNetwork.Persona>

// MARK: - CreateEntityCoordinator
public struct CreateEntityCoordinator<
	_Entity: EntityProtocol & Sendable & Hashable
>: Sendable, ReducerProtocol {
	public typealias Entity = _Entity
	@Dependency(\.factorSourcesClient) var factorSourcesClient
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
					try await factorSourcesClient.getFactorSources()
				}, beforeCreatingEntityWithName: name)))
			}

		case let .internal(.loadFactorSourcesResult(.failure(error), _)):
			errorQueue.schedule(error)
			return .none

		case let .internal(.loadFactorSourcesResult(.success(factorSources), specifiedNameForNewEntityToCreate)):
			precondition(!factorSources.isEmpty)

			if state.config.specificGenesisFactorInstanceDerivationStrategy == nil, factorSources.count > 1, factorSources.contains(where: \.supportsOlympia) {
				return goToStep1SelectGenesisFactorSource(
					entityName: specifiedNameForNewEntityToCreate,
					factorSources: factorSources,
					state: &state
				)
			} else {
				let genesisFactorInstanceDerivationStrategy: GenesisFactorInstanceDerivationStrategy = {
					if let specific = state.config.specificGenesisFactorInstanceDerivationStrategy {
						return specific
					}
					return .loadMnemonicFromKeychainForFactorSource(factorSources.device)
				}()

				return goToStep2Creation(
					curve: .curve25519, // The babylon execution path, safe to default to curve25519
					entityName: specifiedNameForNewEntityToCreate,
					genesisFactorInstanceDerivationStrategy: genesisFactorInstanceDerivationStrategy,
					state: &state
				)
			}

		case let .child(.step1_selectGenesisFactorSource(.delegate(.confirmedFactorSource(factorSource, specifiedNameForNewEntityToCreate, curve)))):
			return goToStep2Creation(
				curve: curve,
				entityName: specifiedNameForNewEntityToCreate,
				genesisFactorInstanceDerivationStrategy: .loadMnemonicFromKeychainForFactorSource(factorSource),
				state: &state
			)

		case let .child(.step2_creationOfEntity(.delegate(.createdEntity(newEntity)))):
			return goToStep3Completion(
				entity: newEntity,
				state: &state
			)

		case .child(.step2_creationOfEntity(.delegate(.createEntityFailed))):
			switch state.step {
			case let .step2_creationOfEntity(createState):
				state.step = .step0_nameNewEntity(
					.init(
						isFirst: state.config.isFirstEntity,
						inputtedEntityName: createState.name.rawValue, // preserve the name
						sanitizedName: createState.name
					)
				)
			default:
				// Should not happen...
				state.step = .step0_nameNewEntity(.init(config: state.config))
			}

			return .none

		case .child(.step3_completion(.delegate(.completed))):
			return .run { send in
				await send(.delegate(.completed))
			}

		case .child, .delegate:
			return .none
		}
	}

	private func goToStep1SelectGenesisFactorSource(
		entityName: NonEmpty<String>,
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
		curve: Slip10Curve,
		entityName: NonEmpty<String>,
		genesisFactorInstanceDerivationStrategy: GenesisFactorInstanceDerivationStrategy,
		state: inout State
	) -> EffectTask<Action> {
		state.step = .step2_creationOfEntity(.init(
			curve: curve,
			networkID: state.config.specificNetworkID,
			name: entityName,
			genesisFactorInstanceDerivationStrategy: genesisFactorInstanceDerivationStrategy
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

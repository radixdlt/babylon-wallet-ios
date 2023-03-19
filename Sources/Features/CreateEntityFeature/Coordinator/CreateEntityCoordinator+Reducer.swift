import Cryptography
import FactorSourcesClient
import FeaturePrelude

public typealias CreateAccountCoordinator = CreateEntityCoordinator<OnNetwork.Account>
public typealias CreatePersonaCoordinator = CreateEntityCoordinator<OnNetwork.Persona>

// MARK: - CreateEntityCoordinator
public struct CreateEntityCoordinator<
	_Entity: EntityProtocol & Sendable & Hashable
>: Sendable, FeatureReducer {
	public typealias Entity = _Entity

	public struct State: Sendable, Hashable {
		public enum Step: Sendable, Hashable {
			case step0_nameNewEntity(NameNewEntity<Entity>.State)
			case step1_selectGenesisFactorSource(SelectGenesisFactorSource.State)
			case step2_creationOfEntity(CreationOfEntity<Entity>.State)
			case step3_completion(NewEntityCompletion<Entity>.State)
		}

		public var step: Step
		public let config: CreateEntityConfig

		public init(
			step: Step? = nil,
			config: CreateEntityConfig
		) {
			self.config = config
			self.step = step ?? .step0_nameNewEntity(.init(config: config))
		}

		var shouldDisplayNavBar: Bool {
			guard
				config.canBeDismissed
			else { return false }
			switch step {
			case .step0_nameNewEntity, .step1_selectGenesisFactorSource: return true
			case .step2_creationOfEntity, .step3_completion: return false
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadFactorSourcesResult(TaskResult<FactorSources>, beforeCreatingEntityWithName: NonEmptyString)
	}

	public enum ChildAction: Sendable, Equatable {
		public typealias Entity = CreateEntityCoordinator.Entity
		case step0_nameNewEntity(NameNewEntity<Entity>.Action)
		case step1_selectGenesisFactorSource(SelectGenesisFactorSource.Action)
		case step2_creationOfEntity(CreationOfEntity<Entity>.Action)
		case step3_completion(NewEntityCompletion<Entity>.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
		case completed
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.step, action: /Action.self) {
			EmptyReducer()
				.ifCaseLet(/State.Step.step0_nameNewEntity, action: /Action.child .. ChildAction.step0_nameNewEntity) {
					NameNewEntity<Entity>()
				}
				.ifCaseLet(/State.Step.step1_selectGenesisFactorSource, action: /Action.child .. ChildAction.step1_selectGenesisFactorSource) {
					SelectGenesisFactorSource()
				}
				.ifCaseLet(/State.Step.step2_creationOfEntity, action: /Action.child .. ChildAction.step2_creationOfEntity) {
					CreationOfEntity<Entity>()
				}
				.ifCaseLet(/State.Step.step3_completion, action: /Action.child .. ChildAction.step3_completion) {
					NewEntityCompletion<Entity>()
				}
		}
		Reduce(core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeButtonTapped:
			precondition(state.config.canBeDismissed)
			return .send(.delegate(.dismiss))
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadFactorSourcesResult(.failure(error), _):
			errorQueue.schedule(error)
			return .none

		case let .loadFactorSourcesResult(.success(factorSources), specifiedNameForNewEntityToCreate):
			precondition(!factorSources.isEmpty)
			let hdOnDeviceFactorSources = factorSources.hdOnDeviceFactorSource()

			// We ALWAYS use "babylon" `device` factor source and `Curve25519` for Personas.
			// However, when creating accounts if we have multiple `device` factors sources, or
			// in general if we have an "olympia" `devive` factor source, we let user choose.
			if Entity.entityKind == .account, hdOnDeviceFactorSources.count > 1 || factorSources.contains(where: \.supportsOlympia)
			{
				return goToStep1SelectGenesisFactorSource(
					entityName: specifiedNameForNewEntityToCreate,
					hdOnDeviceFactorSources: hdOnDeviceFactorSources,
					state: &state
				)
			} else {
				return goToStep2Creation(
					curve: .curve25519, // The babylon execution path, safe to default to curve25519
					entityName: specifiedNameForNewEntityToCreate,
					hdOnDeviceFactorSource: hdOnDeviceFactorSources.first,
					state: &state
				)
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .step0_nameNewEntity(.delegate(.named(name))):
			return .run { send in
				await send(.internal(.loadFactorSourcesResult(TaskResult {
					try await factorSourcesClient.getFactorSources()
				}, beforeCreatingEntityWithName: name)))
			}

		case let .step1_selectGenesisFactorSource(.delegate(.confirmedFactorSource(factorSource, specifiedNameForNewEntityToCreate, curve))):
			return goToStep2Creation(
				curve: curve,
				entityName: specifiedNameForNewEntityToCreate,
				hdOnDeviceFactorSource: factorSource,
				state: &state
			)

		case let .step2_creationOfEntity(.delegate(.createdEntity(newEntity))):
			return goToStep3Completion(
				entity: newEntity,
				state: &state
			)

		case .step2_creationOfEntity(.delegate(.createEntityFailed)):
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

		case .step3_completion(.delegate(.completed)):
			return .run { send in
				await send(.delegate(.completed))
			}

		default:
			return .none
		}
	}

	private func goToStep1SelectGenesisFactorSource(
		entityName: NonEmpty<String>,
		hdOnDeviceFactorSources: NonEmpty<IdentifiedArrayOf<HDOnDeviceFactorSource>>,
		state: inout State
	) -> EffectTask<Action> {
		state.step = .step1_selectGenesisFactorSource(
			.init(
				specifiedNameForNewEntityToCreate: entityName,
				hdOnDeviceFactorSources: hdOnDeviceFactorSources
			)
		)
		return .none
	}

	private func goToStep2Creation(
		curve: Slip10Curve,
		entityName: NonEmpty<String>,
		hdOnDeviceFactorSource: HDOnDeviceFactorSource,
		state: inout State
	) -> EffectTask<Action> {
		state.step = .step2_creationOfEntity(.init(
			curve: curve,
			networkID: state.config.specificNetworkID,
			name: entityName,
			hdOnDeviceFactorSource: hdOnDeviceFactorSource
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

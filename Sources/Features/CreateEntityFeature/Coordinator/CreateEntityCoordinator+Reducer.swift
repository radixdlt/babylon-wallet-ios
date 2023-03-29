import Cryptography
import FactorSourcesClient
import FeaturePrelude

public typealias CreateAccountCoordinator = CreateEntityCoordinator<Profile.Network.Account>
public typealias CreatePersonaCoordinator = CreateEntityCoordinator<Profile.Network.Persona>

// MARK: - CreateEntityCoordinator
public struct CreateEntityCoordinator<
	_Entity: EntityProtocol & Sendable & Hashable
>: Sendable, FeatureReducer {
	public typealias Entity = _Entity

	public struct State: Sendable, Hashable {
		public enum Step: Sendable, Hashable {
			case step0_introduction(IntroductionToEntity<Entity>.State)
			case step1_nameNewEntity(NameNewEntity<Entity>.State)
			case step2_selectGenesisFactorSource(SelectGenesisFactorSource.State)
			case step3_creationOfEntity(CreationOfEntity<Entity>.State)
			case step4_completion(NewEntityCompletion<Entity>.State)
		}

		public var step: Step
		public let config: CreateEntityConfig

		public init(
			step: Step? = nil,
			config: CreateEntityConfig,
			displayIntroduction: (CreateEntityConfig) -> Bool
		) {
			self.config = config
			if let step {
				self.step = step
			} else {
				if displayIntroduction(config) {
					self.step = .step0_introduction(.init())
				} else {
					self.step = .step1_nameNewEntity(.init(config: config))
				}
			}
		}

		var shouldDisplayNavBar: Bool {
			guard
				config.canBeDismissed
			else { return false }
			switch step {
			case .step0_introduction, .step1_nameNewEntity, .step2_selectGenesisFactorSource: return true
			case .step3_creationOfEntity, .step4_completion: return false
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
		case step0_introduction(IntroductionToEntity<Entity>.Action)
		case step1_nameNewEntity(NameNewEntity<Entity>.Action)
		case step2_selectGenesisFactorSource(SelectGenesisFactorSource.Action)
		case step3_creationOfEntity(CreationOfEntity<Entity>.Action)
		case step4_completion(NewEntityCompletion<Entity>.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismissed
		case completed
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.dismiss) var dismiss

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		children
		Reduce(core)
	}

	var children: some ReducerProtocolOf<Self> {
		Scope(state: \.step, action: /Action.self) {
			EmptyReducer()
				.ifCaseLet(/State.Step.step0_introduction, action: /Action.child .. ChildAction.step0_introduction) {
					IntroductionToEntity<Entity>()
				}
				.ifCaseLet(/State.Step.step1_nameNewEntity, action: /Action.child .. ChildAction.step1_nameNewEntity) {
					NameNewEntity<Entity>()
				}
				.ifCaseLet(/State.Step.step2_selectGenesisFactorSource, action: /Action.child .. ChildAction.step2_selectGenesisFactorSource) {
					SelectGenesisFactorSource()
				}
				.ifCaseLet(/State.Step.step3_creationOfEntity, action: /Action.child .. ChildAction.step3_creationOfEntity) {
					CreationOfEntity<Entity>()
				}
				.ifCaseLet(/State.Step.step4_completion, action: /Action.child .. ChildAction.step4_completion) {
					NewEntityCompletion<Entity>()
				}
		}
	}
}

extension CreateEntityCoordinator {
	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeButtonTapped:
			precondition(state.config.canBeDismissed)
			return .run { send in
				await send(.delegate(.dismissed))
				await dismiss()
			}
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
		case .step0_introduction(.delegate(.done)):
			state.step = .step1_nameNewEntity(.init(config: state.config))
			return .none

		case let .step1_nameNewEntity(.delegate(.named(name))):
			return .run { send in
				await send(.internal(.loadFactorSourcesResult(TaskResult {
					try await factorSourcesClient.getFactorSources()
				}, beforeCreatingEntityWithName: name)))
			}

		case let .step2_selectGenesisFactorSource(.delegate(.confirmedFactorSource(factorSource, specifiedNameForNewEntityToCreate, curve))):
			return goToStep2Creation(
				curve: curve,
				entityName: specifiedNameForNewEntityToCreate,
				hdOnDeviceFactorSource: factorSource,
				state: &state
			)

		case let .step3_creationOfEntity(.delegate(.createdEntity(newEntity))):
			return goToStep3Completion(
				entity: newEntity,
				state: &state
			)

		case .step3_creationOfEntity(.delegate(.createEntityFailed)):
			switch state.step {
			case let .step3_creationOfEntity(createState):
				state.step = .step1_nameNewEntity(
					.init(
						isFirst: state.config.isFirstEntity,
						inputtedEntityName: createState.name.rawValue, // preserve the name
						sanitizedName: createState.name
					)
				)
			default:
				// Should not happen...
				state.step = .step1_nameNewEntity(.init(config: state.config))
			}

			return .none

		case .step4_completion(.delegate(.completed)):
			return .run { send in
				await send(.delegate(.completed))
				await dismiss()
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
		state.step = .step2_selectGenesisFactorSource(
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
		state.step = .step3_creationOfEntity(.init(
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
		state.step = .step4_completion(.init(
			entity: entity,
			config: state.config
		))
		return .none
	}
}

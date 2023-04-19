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
			case step2_creationOfEntity(CreationOfEntity<Entity>.State)
			case step3_completion(NewEntityCompletion<Entity>.State)
		}

		public var step: Step
		public let config: CreateEntityConfig

		public init(
			step: Step? = nil,
			config: CreateEntityConfig,
			displayIntroduction: (CreateEntityConfig) -> Bool = { _ in false }
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
			case .step0_introduction, .step1_nameNewEntity: return true
			case .step2_creationOfEntity, .step3_completion: return false
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadFactorSourcesResult(
			TaskResult<FactorSources>,
			beforeCreatingEntityWithName: NonEmptyString,
			useLedgerAsFactorSource: Bool
		)
	}

	public enum ChildAction: Sendable, Equatable {
		public typealias Entity = CreateEntityCoordinator.Entity
		case step0_introduction(IntroductionToEntity<Entity>.Action)
		case step1_nameNewEntity(NameNewEntity<Entity>.Action)
		case step2_creationOfEntity(CreationOfEntity<Entity>.Action)
		case step3_completion(NewEntityCompletion<Entity>.Action)
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
				.ifCaseLet(/State.Step.step2_creationOfEntity, action: /Action.child .. ChildAction.step2_creationOfEntity) {
					CreationOfEntity<Entity>()
				}
				.ifCaseLet(/State.Step.step3_completion, action: /Action.child .. ChildAction.step3_completion) {
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
		case let .loadFactorSourcesResult(.failure(error), _, _):
			loggerGlobal.error("Failed to load factor sources: \(error)")
			errorQueue.schedule(error)
			return .none

		case let .loadFactorSourcesResult(.success(factorSources), specifiedNameForNewEntityToCreate, useLedgerAsFactorSource):
			precondition(!factorSources.isEmpty)
			let babylonDeviceFactorSources = factorSources.babylonDeviceFactorSources()

			return goToStep2Creation(
				entityName: specifiedNameForNewEntityToCreate,
				genesisFactorSourceSelection: useLedgerAsFactorSource ? .ledger : .device(babylonDeviceFactorSources.first),
				state: &state
			)
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .step0_introduction(.delegate(.done)):
			state.step = .step1_nameNewEntity(.init(config: state.config))
			return .none

		case let .step1_nameNewEntity(.delegate(.proceed(name, useLedgerAsFactorSource))):

			return .run { send in
				await send(.internal(
					.loadFactorSourcesResult(
						TaskResult {
							try await factorSourcesClient.getFactorSources()
						},
						beforeCreatingEntityWithName: name,
						useLedgerAsFactorSource: useLedgerAsFactorSource
					)
				))
			}

		case let .step2_creationOfEntity(.delegate(.createdEntity(newEntity))):
			return goToStep3Completion(
				entity: newEntity,
				state: &state
			)

		case .step2_creationOfEntity(.delegate(.createEntityFailed)):
			switch state.step {
			case let .step2_creationOfEntity(createState):
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

		case .step3_completion(.delegate(.completed)):
			return .run { send in
				await send(.delegate(.completed))
				await dismiss()
			}

		default:
			return .none
		}
	}

	private func goToStep2Creation(
		entityName: NonEmpty<String>,
		genesisFactorSourceSelection: GenesisFactorSourceSelection,
		state: inout State
	) -> EffectTask<Action> {
		state.step = .step2_creationOfEntity(.init(
			networkID: state.config.specificNetworkID,
			name: entityName,
			genesisFactorSourceSelection: genesisFactorSourceSelection
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

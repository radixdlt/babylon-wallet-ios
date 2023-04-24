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
		var root: Destinations.State?
		var path: StackState<Destinations.State> = []

		public let config: CreateEntityConfig

		public init(
			root: Destinations.State? = nil,
			config: CreateEntityConfig,
			displayIntroduction: (CreateEntityConfig) -> Bool = { _ in false }
		) {
			self.config = config
			if let root {
				self.root = root
			} else {
				if displayIntroduction(config) {
					self.root = .step0_introduction(.init())
				} else {
					self.root = .step1_nameNewEntity(.init(config: config))
				}
			}
		}

		var shouldDisplayNavBar: Bool {
			guard config.canBeDismissed else {
				return false
			}
			if let last = path.last {
				if case .step3_completion = last {
					return false
				} else if case let .step2_creationOfEntity(creationOfEntity) = last {
					// do not show back button when using `device` factor source
					return creationOfEntity.useLedgerAsFactorSource
				} else {
					return true
				}
			}
			return true
		}
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case step0_introduction(IntroductionToEntity<Entity>.State)
			case step1_nameNewEntity(NameNewEntity<Entity>.State)
			case step2_creationOfEntity(CreationOfEntity<Entity>.State)
			case step3_completion(NewEntityCompletion<Entity>.State)
		}

		public enum Action: Sendable, Equatable {
			public typealias Entity = CreateEntityCoordinator.Entity
			case step0_introduction(IntroductionToEntity<Entity>.Action)
			case step1_nameNewEntity(NameNewEntity<Entity>.Action)
			case step2_creationOfEntity(CreationOfEntity<Entity>.Action)
			case step3_completion(NewEntityCompletion<Entity>.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.step0_introduction, action: /Action.step0_introduction) {
				IntroductionToEntity<Entity>()
			}
			Scope(state: /State.step1_nameNewEntity, action: /Action.step1_nameNewEntity) {
				NameNewEntity<Entity>()
			}
			Scope(state: /State.step2_creationOfEntity, action: /Action.step2_creationOfEntity) {
				CreationOfEntity<Entity>()
			}
			Scope(state: /State.step3_completion, action: /Action.step3_completion) {
				NewEntityCompletion<Entity>()
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
		case root(Destinations.Action)
		case path(StackAction<Destinations.Action>)
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
		Reduce(core)
			.ifLet(\.root, action: /Action.child .. ChildAction.root) {
				Destinations()
			}
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Destinations()
			}
	}
}

extension CreateEntityCoordinator {
	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeButtonTapped:
			assert(state.config.canBeDismissed)
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
			let ledgerFactorSources: [FactorSource] = factorSources.filter { $0.kind == .ledgerHQHardwareWallet }
			let source: GenesisFactorSourceSelection = useLedgerAsFactorSource ? .ledger(ledgerFactorSources: ledgerFactorSources) : .device(babylonDeviceFactorSources.first)

			return goToStep2Creation(
				entityName: specifiedNameForNewEntityToCreate,
				genesisFactorSourceSelection: source,
				state: &state
			)
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .root(.step0_introduction(.delegate(.done))):
			state.path.append(.step1_nameNewEntity(.init(config: state.config)))
			return .none

		case
			let .root(.step1_nameNewEntity(.delegate(.proceed(name, useLedgerAsFactorSource)))),
			let .path(.element(_, action: .step1_nameNewEntity(.delegate(.proceed(name, useLedgerAsFactorSource))))):

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

		case let .path(.element(_, action: .step2_creationOfEntity(.delegate(.createdEntity(newEntity))))):
			return goToStep3Completion(
				entity: newEntity,
				state: &state
			)

		case .path(.element(_, action: .step2_creationOfEntity(.delegate(.createEntityFailed)))):
			state.path.removeLast()
			return .none

		case .path(.element(_, action: .step3_completion(.delegate(.completed)))):
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
		state.path.append(.step2_creationOfEntity(.init(
			networkID: state.config.specificNetworkID,
			name: entityName,
			genesisFactorSourceSelection: genesisFactorSourceSelection
		)))
		return .none
	}

	private func goToStep3Completion(
		entity: Entity,
		state: inout State
	) -> EffectTask<Action> {
		state.path.append(.step3_completion(.init(
			entity: entity,
			config: state.config
		)))
		return .none
	}
}

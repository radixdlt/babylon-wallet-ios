import FeaturePrelude

// MARK: - CreateAccountConfig
public struct CreateAccountConfig: CreateEntityStateConfigProtocol {
	public var mode: Mode

	public var networkID: NetworkID?

	public enum Mode: Sendable, Equatable {
		case profile
		case firstAccount
		case anotherAccount
	}

	public init(
		create mode: Mode,
		networkID: NetworkID? = nil
	) {
		self.mode = mode
		self.networkID = networkID
	}
}

public typealias CreateAccountCoordinator = CreateEntityCoordinator<CreateAccountConfig, CreateAccountCompletionState, CreateAccountCompletionAction>

// MARK: - CreateEntityCompletionDestinationProtocol
public protocol CreateEntityCompletionDestinationProtocol: Sendable, Equatable {
	var displayText: String { get }
}

// MARK: - CreateEntityCompletionStateProtocol
public protocol CreateEntityCompletionStateProtocol: Sendable, Equatable {
	associatedtype Entity: EntityProtocol & Sendable & Equatable
	associatedtype Destination: CreateEntityCompletionDestinationProtocol
	var entity: Entity { get }
	var isFirstOnNetwork: Bool { get }
	var destination: Destination { get }
	init(entity: Entity, isFirstOnNetwork: Bool, destination: Destination)
}

// MARK: - CreateEntityCompletionActionProtocol
public protocol CreateEntityCompletionActionProtocol: Sendable, Equatable {
	static var completed: Self { get }
}

// MARK: - CreateAccountCompletionState
public struct CreateAccountCompletionState: CreateEntityCompletionStateProtocol {
	public typealias Entity = OnNetwork.Account

	public enum Destination: String, CreateEntityCompletionDestinationProtocol {
		case home
		case chooseAccounts

		public var displayText: String {
			switch self {
			case .home:
				return L10n.CreateEntity.Completion.Destination.home
			case .chooseAccounts:
				return L10n.CreateEntity.Completion.Destination.chooseEntities(L10n.Common.Account.kind)
			}
		}
	}

	public var entity: OnNetwork.Account
	public var isFirstOnNetwork: Bool
	public var destination: Destination
	public init(
		entity: Entity,
		isFirstOnNetwork: Bool,
		destination: Destination
	) {
		self.entity = entity
		self.isFirstOnNetwork = isFirstOnNetwork
		self.destination = destination
	}
}

// MARK: - CreateAccountCompletionAction
public enum CreateAccountCompletionAction: CreateEntityCompletionActionProtocol {
	public static var completed: Self { fatalError() }
}

// MARK: - CreateEntityStateConfigProtocol
public protocol CreateEntityStateConfigProtocol: Sendable, Equatable {}

// MARK: - CreateEntityCoordinator
public struct CreateEntityCoordinator<
	StateConfig: CreateEntityStateConfigProtocol,
	CompletionState: CreateEntityCompletionStateProtocol,
	CompletionAction: CreateEntityCompletionActionProtocol

>: Sendable, ReducerProtocol {
	public typealias Entity = CompletionState.Entity
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.step, action: /Action.self) {
			EmptyReducer()
				.ifCaseLet(/State.Step.step0_nameNewEntity, action: /Action.child .. Action.ChildAction.step0_nameNewEntity) {
					NameNewEntity()
				}
				.ifCaseLet(/State.Step.step1_selectGenesisFactorSource, action: /Action.child .. Action.ChildAction.step1_selectGenesisFactorSource) {
					SelectGenesisFactorSource()
				}
			//				.ifCaseLet(/State.Root.entityCompletion, action: /Action.child .. Action.ChildAction.entityCompletion) {
			//                    EntityCompletion()
			//				}
		}
		Reduce(self.core)
	}

	private func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case let .child(.step0_nameNewEntity(.delegate(.named(name)))):
			state.step = .step1_selectGenesisFactorSource(.init(specifiedNameForNewEntityToCreate: name))
			return .none

		case .child(.step0_nameNewEntity(.delegate(.dismiss))):
			return .run { send in
				await send(.delegate(.dismissed))
			}

		case let .child(.step1_selectGenesisFactorSource(.delegate(.confirmedFactorSource(factorSource, specifiedNameForNewEntityToCreate)))):
			state.step = .step2_creationOfEntity(.init(name: specifiedNameForNewEntityToCreate, genesisFactorSource: factorSource))
			return .none

		case let .child(.step2_creationOfEntity(.delegate(.createdEntity(newEntity)))):
			let isFirstOnNetwork: Bool = { () -> Bool in fatalError("todo, propagate isFirstOnNetwork") }()
			state.step = .step3_completion(
				.init(
					entity: newEntity,
					isFirstOnNetwork: isFirstOnNetwork,
					destination: state.completionDestination
				)
			)
			return .none

		default:
			return .none
		}
	}
}

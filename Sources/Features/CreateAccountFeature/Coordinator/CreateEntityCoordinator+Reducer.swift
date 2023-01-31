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
	associatedtype Entity: EntityProtocol
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
				return L10n.CreateAccount.Completion.Destination.home
			case .chooseAccounts:
				return L10n.CreateAccount.Completion.Destination.chooseAccounts
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
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
//		Scope(state: \.root, action: /Action.self) {
//			EmptyReducer()
//				.ifCaseLet(/State.Root.nameNewEntity, action: /Action.child .. Action.ChildAction.nameNewEntity) {
//					NameNewEntity()
//				}
//				.ifCaseLet(/State.Root.selectGenesisFactorSource, action: /Action.child .. Action.ChildAction.selectGenesisFactorSource) {
//					SelectGenesisFactorSource()
//				}
		////				.ifCaseLet(/State.Root.entityCompletion, action: /Action.child .. Action.ChildAction.entityCompletion) {
//			//                    EntityCompletion()
		////				}
//		}
		Reduce(self.core)
	}

	private func core(state: inout State, action: Action) -> EffectTask<Action> {
//		switch action {
//		case let .child(.nameNewEntity(.delegate(.named))):
//
		//            fatalError()
//		case .child(.nameNewEntity(.delegate(.dismiss))):
//			return .run { send in
//				await send(.delegate(.dismissed))
//			}
//
//		case .child(.accountCompletion(.delegate(.completed))):
//			return .run { send in
//				await send(.delegate(.completed))
//			}
//		default:
//			return .none
//		}
		fatalError()
	}
}

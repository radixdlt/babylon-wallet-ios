import FeaturePrelude

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

// MARK: - CreateAccountCompletionDestination
public enum CreateAccountCompletionDestination: String, CreateEntityCompletionDestinationProtocol {
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

// MARK: - CreateEntityCoordinator
public struct CreateEntityCoordinator<CompletionState: CreateEntityCompletionStateProtocol, CompletionAction: CreateEntityCompletionActionProtocol>: Sendable, ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.root, action: /Action.self) {
			EmptyReducer()
				.ifCaseLet(/State.Root.nameNewEntity, action: /Action.child .. Action.ChildAction.nameNewEntity) {
					NameNewEntity()
				}
				.ifCaseLet(/State.Root.selectGenesisFactorSource, action: /Action.child .. Action.ChildAction.selectGenesisFactorSource) {
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
		case let .child(.nameNewEntity(.delegate(.named))):
			state.root = .completion(<#T##AccountCompletion.State#>)

//            state.root = .accountCompletion(
//				.init(
//					account: account,
//					isFirstAccount: isFirstAccount,
//					destination: state.completionDestination
//				)
//			)
//			return .none

		case .child(.nameNewEntity(.delegate(.dismiss))):
			return .run { send in
				await send(.delegate(.dismissed))
			}

		case .child(.accountCompletion(.delegate(.completed))):
			return .run { send in
				await send(.delegate(.completed))
			}
		default:
			return .none
		}
	}
}

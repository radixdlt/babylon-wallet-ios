import FeaturePrelude
import AccountPortfoliosClient
import SharedModels

public struct FungibleTokenList: Sendable, FeatureReducer {
        public struct State: Sendable, Hashable {
                public var xrdToken: Row.State?
                public var nonXrdTokens: IdentifiedArrayOf<Row.State>

//		@PresentationState
//		public var destination: Destinations.State?

                public init(
                        xrdToken: Row.State? = nil,
                        nonXrdTokens: IdentifiedArrayOf<Row.State> = []
                ) {
                        self.xrdToken = xrdToken
                        self.nonXrdTokens = nonXrdTokens
                }
	}

	public enum ViewAction: Sendable, Equatable {
                case selectedTokenChanged(AccountPortfolio.FungibleToken?)
                case scrolledToLoadMore
	}

	public enum ChildAction: Sendable, Equatable {
		//case destination(PresentationAction<Destinations.Action>)
                case xrdRow(FungibleTokenList.Row.Action)
                case nonXRDRow(FungibleTokenList.Row.State.ID, FungibleTokenList.Row.Action)
	}

        public enum DelegateAction: Sendable, Equatable {
                case loadMoreTokens
        }

//	public struct Destinations: Sendable, ReducerProtocol {
//		public enum State: Sendable, Hashable {
//			case details(FungibleTokenDetails.State)
//		}
//
//		public enum Action: Sendable, Equatable {
//			case details(FungibleTokenDetails.Action)
//		}
//
//		public var body: some ReducerProtocolOf<Self> {
//			Scope(state: /State.details, action: /Action.details) {
//				FungibleTokenDetails()
//			}
//		}
//	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
                        .ifLet(\.xrdToken, action: /Action.child .. ChildAction.xrdRow) {
                                FungibleTokenList.Row()
                        }
                        .forEach(\.nonXrdTokens, action: /Action.child .. ChildAction.nonXRDRow, element: {
                                FungibleTokenList.Row()
			})
//			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
//				Destinations()
//			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .selectedTokenChanged(token):
//			if let token {
//				state.destination = .details(token)
//			} else {
//				state.destination = nil
//			}
			return .none
                case .scrolledToLoadMore:
                        return .send(.delegate(.loadMoreTokens))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
                case let .xrdRow(.delegate(.selected(token))):
                        return .none
                case let .nonXRDRow(_, .delegate(.selected(token))):
                        return .none
		default:
			return .none
		}
	}
}

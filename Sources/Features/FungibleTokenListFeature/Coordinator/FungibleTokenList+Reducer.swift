import FeaturePrelude
import FungibleTokenDetailsFeature
import AccountPortfoliosClient

public struct FungibleTokenList: Sendable, FeatureReducer {
        public struct State: Sendable, Hashable {
                public var xrdToken: FungibleToken
                public var nonXrdTokens: [FungibleToken]

		@PresentationState
		public var destination: Destinations.State?

                public init(xrdToken: FungibleToken, nonXrdTokens: [FungibleToken], destination: FungibleTokenList.Destinations.State? = nil) {
                        self.xrdToken = xrdToken
                        self.nonXrdTokens = nonXrdTokens
                        self.destination = destination
                }
	}

	public enum ViewAction: Sendable, Equatable {
		case selectedTokenChanged(FungibleToken?)
                case scrolledToLoadMore
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
                case row(FungibleTokenList.Row.Action)
	}

        public enum DelegateAction: Sendable, Equatable {
                case loadMoreTokens
        }

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case details(FungibleTokenDetails.State)
		}

		public enum Action: Sendable, Equatable {
			case details(FungibleTokenDetails.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.details, action: /Action.details) {
				FungibleTokenDetails()
			}
		}
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
                        .ifLet(\.xrdToken, action: /Action.child .. ChildAction.row) {
                                FungibleTokenList.Row()
                        }
			.forEach(\.nonXrdTokens, action: /Action.child .. ChildAction.row) {
                                FungibleTokenList.Row()
			}
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .selectedTokenChanged(token):
			if let token {
				state.destination = .details(token)
			} else {
				state.destination = nil
			}
			return .none
                case .scrolledToLoadMore:
                        return .send(.delegate(.loadMoreTokens))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .section(_, action: .child(.asset(_, action: .delegate(.selected(let token))))):
			state.destination = .details(token)
			return .none
		case .destination(.presented(.details(.delegate(.dismiss)))):
			state.destination = nil
			return .none
		default:
			return .none
		}
	}
}

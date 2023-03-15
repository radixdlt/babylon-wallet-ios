import FeaturePrelude

public struct NonFungibleTokenList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var rows: IdentifiedArrayOf<NonFungibleTokenList.Row.State>

		@PresentationState
		public var destination: Destinations.State?

		public init(rows: IdentifiedArrayOf<NonFungibleTokenList.Row.State>) {
			self.rows = rows
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case selectedTokenChanged(NonFungibleTokenList.Detail.State?)
	}

	public enum ChildAction: Sendable, Equatable {
		case asset(id: NonFungibleTokenContainer.ID, action: NonFungibleTokenList.Row.Action)
		case destination(PresentationAction<Destinations.Action>)
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case details(NonFungibleTokenList.Detail.State)
		}

		public enum Action: Sendable, Equatable {
			case details(NonFungibleTokenList.Detail.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.details, action: /Action.details) {
				NonFungibleTokenList.Detail()
			}
		}
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.forEach(\.rows, action: /Action.child .. ChildAction.asset) {
				NonFungibleTokenList.Row()
			}
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .selectedTokenChanged(detailsState):
			if let detailsState {
				state.destination = .details(detailsState)
			} else {
				state.destination = nil
			}
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .asset(_, action: .delegate(.selected(detailsState))):
			state.destination = .details(detailsState)
			return .none

		case .destination(.presented(.details(.delegate(.dismiss)))):
			state.destination = nil
			return .none

		default:
			return .none
		}
	}
}

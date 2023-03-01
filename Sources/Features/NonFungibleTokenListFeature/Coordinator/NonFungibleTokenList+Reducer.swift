import FeaturePrelude

public struct NonFungibleTokenList: Sendable, ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce<State, Action> { state, action in
			switch action {
			case let .child(.asset(_, action: .delegate(.selected(detailsState)))):
				state.destination = .details(detailsState)
				return .none
			case let .internal(.view(.selectedTokenChanged(detailsState))):
				if let detailsState {
					state.destination = .details(detailsState)
				} else {
					state.destination = nil
				}
				return .none
			case .child(.destination(.presented(.details(.delegate(.dismiss))))):
				state.destination = nil
				return .none
			case .child:
				return .none
			}
		}
		.forEach(\.rows, action: /Action.child .. Action.ChildAction.asset) {
			NonFungibleTokenList.Row()
		}
		.ifLet(\.$destination, action: /Action.child .. Action.ChildAction.destination) {
			Destinations()
		}
	}
}

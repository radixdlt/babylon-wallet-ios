import FeaturePrelude
import FungibleTokenDetailsFeature

public struct FungibleTokenList: Sendable, ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce<State, Action> { state, action in
			switch action {
			case .child(.section(_, action: .child(.asset(_, action: .delegate(.selected(let token)))))):
				state.destination = .details(token)
				return .none
			case let .internal(.view(.selectedTokenChanged(token))):
				if let token {
					state.destination = .details(token)
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
		.forEach(\.sections, action: /Action.child .. Action.ChildAction.section) {
			FungibleTokenList.Section()
		}
		.presentationDestination(\.$destination, action: /Action.child .. Action.ChildAction.destination) {
			Destinations()
		}
	}
}

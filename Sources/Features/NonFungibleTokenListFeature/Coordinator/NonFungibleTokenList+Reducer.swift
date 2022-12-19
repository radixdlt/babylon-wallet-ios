import ComposableArchitecture

public struct NonFungibleTokenList: ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce { state, action in
			switch action {
			case let .child(.asset(_, action: .delegate(.selected(token)))):
				state.selectedToken = token
				return .none
			case let .internal(.view(.selectedTokenChanged(token))):
				state.selectedToken = token
				return .none
			case .child(.details(.delegate(.closeButtonTapped))):
				state.selectedToken = nil
				return .none
			case .child:
				return .none
			}
		}
		.forEach(\.rows, action: /Action.child .. Action.ChildAction.asset) {
			NonFungibleTokenList.Row()
		}
		.ifLet(\.selectedToken, action: /Action.child .. Action.ChildAction.details) {
			NonFungibleTokenList.Detail()
		}
	}
}

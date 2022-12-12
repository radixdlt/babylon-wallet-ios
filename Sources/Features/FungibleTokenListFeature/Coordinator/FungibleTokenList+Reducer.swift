import ComposableArchitecture

public struct FungibleTokenList: ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce { state, action in
			switch action {
			case .child(.section(_, action: .child(.asset(_, action: .delegate(.selected(let token)))))):
				state.selectedToken = token
				return .none
			case .child:
				return .none
			case .internal:
				return .none
			}
		}
		.forEach(\.sections, action: /Action.child .. Action.ChildAction.section) {
			FungibleTokenList.Section()
		}
	}
}

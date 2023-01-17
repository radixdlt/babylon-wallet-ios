import FeaturePrelude
import FungibleTokenDetailsFeature

public struct FungibleTokenList: Sendable, ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce { state, action in
			switch action {
			case .child(.section(_, action: .child(.asset(_, action: .delegate(.selected(let token)))))):
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
		.forEach(\.sections, action: /Action.child .. Action.ChildAction.section) {
			FungibleTokenList.Section()
		}
		.ifLet(\.selectedToken, action: /Action.child .. Action.ChildAction.details) {
			FungibleTokenDetails()
		}
	}
}

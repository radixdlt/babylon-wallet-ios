import FeaturePrelude
import FungibleTokenListFeature
import NonFungibleTokenListFeature

public struct AssetsView: Sendable, FeatureReducer {
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.nonFungibleTokenList, action: /Action.child .. ChildAction.nonFungibleTokenList) {
			NonFungibleTokenList()
		}

		Scope(state: \.fungibleTokenList, action: /Action.child .. ChildAction.fungibleTokenList) {
			FungibleTokenList()
		}

		Reduce(self.core)
	}

	public func reduceView(into state: inout State, action: ViewAction) -> EffectTask<Action> {
		switch action {
		case let .listSelectorTapped(type):
			state.type = type
			return .none
		}
	}
}

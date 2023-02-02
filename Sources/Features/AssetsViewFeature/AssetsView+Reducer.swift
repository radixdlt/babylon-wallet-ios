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

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .listSelectorTapped(type):
			state.type = type
			return .none
		}
	}
}

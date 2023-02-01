import FeaturePrelude
import FungibleTokenListFeature
import NonFungibleTokenListFeature

public struct AssetsView: Sendable, Feature {
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

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case let .view(.listSelectorTapped(type)):
			state.type = type
			return .none

		case .child, .delegate:
			return .none
		}
	}
}

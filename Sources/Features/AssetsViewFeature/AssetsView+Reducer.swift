import ComposableArchitecture
import FungibleTokenListFeature
import NonFungibleTokenListFeature

public struct AssetsView: ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.nonFungibleTokenList, action: /Action.child .. Action.ChildAction.nonFungibleTokenList) {
			NonFungibleTokenList()
		}

		Scope(state: \.fungibleTokenList, action: /Action.child .. Action.ChildAction.fungibleTokenList) {
			FungibleTokenList()
		}

		Reduce(self.core)
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case let .internal(.view(.listSelectorTapped(type))):
			state.type = type
			return .none

		case .child, .delegate:
			return .none
		}
	}
}

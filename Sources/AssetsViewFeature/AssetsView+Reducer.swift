import ComposableArchitecture
import FungibleTokenListFeature
import NonFungibleTokenListFeature

public extension AssetsView {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer.combine(
		NonFungibleTokenList.reducer
			.pullback(
				state: \.nonFungibleTokenList,
				action: /AssetsView.Action.nonFungibleTokenList,
				environment: { _ in NonFungibleTokenList.Environment() }
			),

		Reducer { state, action, _ in
			switch action {
			case let .internal(.user(.listSelectorTapped(type))):
				state.type = type
				return .none
			case .coordinate:
				return .none
			case .fungibleTokenList:
				return .none
			case .nonFungibleTokenList:
				return .none
			}
		}
	)
}

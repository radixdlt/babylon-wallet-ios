import ComposableArchitecture
import FungibleTokenListFeature

public extension AssetsView {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer.combine(
		Reducer { _, action, _ in
			switch action {
			case .internal:
				return .none
			case .coordinate:
				return .none
			case .fungibleTokenList:
				return .none
			}
		}
	)
}

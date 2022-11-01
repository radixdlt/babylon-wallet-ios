import ComposableArchitecture

public extension NonFungibleTokenList.Row {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<RowState, Action, Environment>
	static let reducer = Reducer { state, action, _ in
		switch action {
		case .internal(.user(.toggleIsExpanded)):
			state.isExpanded.toggle()
			return .none
		case .coordinate:
			return .none
		}
	}
}

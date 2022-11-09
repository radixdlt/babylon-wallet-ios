import ComposableArchitecture

public extension NonFungibleTokenList.Row {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<RowState, Action, Environment>
	static let reducer = Reducer { state, action, _ in
		switch action {
		case .internal(.view(.isExpandedToggled)):
			state.isExpanded.toggle()
			return .none

		case .delegate:
			return .none
		}
	}
}

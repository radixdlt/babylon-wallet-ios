import ComposableArchitecture

public struct NonFungibleTokenList: ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocol<State, Action> {
		EmptyReducer()
			.forEach(\.rows, action: /Action.child .. Action.ChildAction.asset) {
				NonFungibleTokenList.Row()
			}
	}
}

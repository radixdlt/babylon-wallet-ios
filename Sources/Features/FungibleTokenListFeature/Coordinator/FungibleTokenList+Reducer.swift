import ComposableArchitecture

public struct FungibleTokenList: ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocol<State, Action> {
		EmptyReducer()
			.forEach(\.sections, action: /Action.child .. Action.ChildAction.section) {
				FungibleTokenList.Section()
			}
	}
}

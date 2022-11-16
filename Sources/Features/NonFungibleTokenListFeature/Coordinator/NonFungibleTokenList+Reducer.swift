import ComposableArchitecture

public struct NonFungibleTokenList: ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		EmptyReducer()
			.forEach(\.rows, action: /Action.child .. Action.ChildAction.asset) {
				NonFungibleTokenList.Row()
			}
	}
}

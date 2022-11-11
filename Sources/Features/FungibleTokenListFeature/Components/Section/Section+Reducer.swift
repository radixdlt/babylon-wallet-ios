import ComposableArchitecture

public extension FungibleTokenList {
	struct Section: ReducerProtocol {
		public init() {}

		public var body: some ReducerProtocol<State, Action> {
			EmptyReducer()
				.forEach(\.assets, action: /Action.child .. Action.ChildAction.asset) {
					FungibleTokenList.Row()
				}
		}
	}
}

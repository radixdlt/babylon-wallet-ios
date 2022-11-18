import ComposableArchitecture

public extension FungibleTokenList {
	struct Section: ReducerProtocol {
		public init() {}

		public var body: some ReducerProtocolOf<Self> {
			EmptyReducer()
				.forEach(\.assets, action: /Action.child .. Action.ChildAction.asset) {
					FungibleTokenList.Row()
				}
		}
	}
}

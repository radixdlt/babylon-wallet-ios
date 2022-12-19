import ComposableArchitecture
import NonFungibleTokenDetailsFeature

public struct NonFungibleTokenList: ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		EmptyReducer()
			.forEach(\.rows, action: /Action.child .. Action.ChildAction.asset) {
				NonFungibleTokenList.Row()
			}
			.ifLet(\.selectedToken, action: /Action.child .. Action.ChildAction.details) {
				NonFungibleTokenDetails()
			}
	}
}

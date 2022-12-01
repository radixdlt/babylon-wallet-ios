import ComposableArchitecture

// MARK: - FungibleTokenDetails
public struct FungibleTokenDetails: ReducerProtocol {
	public init() {}
}

public extension FungibleTokenDetails {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		.none
	}
}

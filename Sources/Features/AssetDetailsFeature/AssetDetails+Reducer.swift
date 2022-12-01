import ComposableArchitecture

// MARK: - AssetDetails
public struct AssetDetails: ReducerProtocol {
	public init() {}
}

public extension AssetDetails {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		.none
	}
}

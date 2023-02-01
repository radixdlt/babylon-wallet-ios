import FeaturePrelude

// MARK: - SelectGenesisFactorSource
public struct SelectGenesisFactorSource: Sendable, ReducerProtocol {
	public init() {}
}

public extension SelectGenesisFactorSource {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		.none
	}
}

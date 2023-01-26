import FeaturePrelude

// MARK: - ___VARIABLE_featureName___
public struct ___VARIABLE_featureName___: Sendable, ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
	}

	func core(into state: inout State, action: Action) -> EffectTask<Action> {
		.none
	}
}

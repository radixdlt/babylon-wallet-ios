import FeaturePrelude

public struct AssetTransfer: Sendable, ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		.none
	}
}

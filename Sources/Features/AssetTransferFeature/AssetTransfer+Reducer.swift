import FeaturePrelude

public struct AssetTransfer: Sendable, ReducerProtocol {
	public init() {}

	@ReducerBuilderOf<Self>
	public var body: some ReducerProtocolOf<Self> {
		Reduce(self.core)
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		.none
	}
}

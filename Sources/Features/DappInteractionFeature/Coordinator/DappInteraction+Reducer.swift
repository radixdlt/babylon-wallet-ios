import FeaturePrelude

// MARK: - DappInteraction
public struct DappInteraction: Sendable, ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
	}

	func core(into state: inout State, action: Action) -> EffectTask<Action> {
		.none
	}
}

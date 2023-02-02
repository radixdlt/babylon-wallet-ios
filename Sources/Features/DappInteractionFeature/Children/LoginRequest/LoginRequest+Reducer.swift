import FeaturePrelude

// MARK: - LoginRequest
public struct LoginRequest: Sendable, ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
	}

	func core(into state: inout State, action: Action) -> EffectTask<Action> {
		.none
	}
}

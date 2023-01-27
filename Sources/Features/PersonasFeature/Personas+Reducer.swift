import FeaturePrelude

// MARK: - Personas
public struct Personas: Sendable, ReducerProtocol {
	public init() {}
}

public extension Personas {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		.none
	}
}

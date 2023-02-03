import FeaturePrelude

// MARK: - PersonaRow
struct PersonaRow: Sendable, ReducerProtocol {
	var body: some ReducerProtocolOf<Self> {
		Reduce(core)
	}

	func core(into state: inout State, action: Action) -> EffectTask<Action> {
		.none
	}
}

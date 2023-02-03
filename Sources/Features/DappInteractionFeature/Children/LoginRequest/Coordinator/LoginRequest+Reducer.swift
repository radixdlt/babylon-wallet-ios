import FeaturePrelude

// MARK: - LoginRequest
public struct LoginRequest: Sendable, ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
	}

	func core(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case let .child(.persona(id: id, action: action)):
			switch action {
			case .internal(.view(.didSelect)):
				state.personas.forEach {
					if $0.id == id {
						if !$0.isSelected {
							state.personas[id: $0.id]?.isSelected = true
						}
					} else {
						state.personas[id: $0.id]?.isSelected = false
					}
				}
				return .none
			}

		case .internal:
			return .none
		}
	}
}

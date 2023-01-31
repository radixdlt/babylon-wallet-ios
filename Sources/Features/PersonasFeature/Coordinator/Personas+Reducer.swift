import FeaturePrelude

// MARK: - Personas
public struct Personas: Sendable, ReducerProtocol {
	public init() {}
}

public extension Personas {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.dismissButtonTapped)):
			return .run { send in
				await send(.delegate(.dismiss))
			}

		case .internal(.view(.createNewPersonaButtonTapped)):
			// TODO: implement
			return .none

		case .delegate:
			return .none

		case .child:
			// TODO: implement
			return .none
		}
	}
}

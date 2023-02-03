import FeaturePrelude

// MARK: - PersonaList
public struct PersonaList: Sendable, ReducerProtocol {
	public init() {}
}

public extension PersonaList {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.dismissButtonTapped)):
			return .run { send in
				await send(.delegate(.dismiss))
			}

		case .internal(.view(.createNewPersonaButtonTapped)):
			return .run { send in
				await send(.delegate(.createNewPersona))
			}

		case .delegate:
			return .none

		case .child:
			// TODO: implement
			return .none
		}
	}
}

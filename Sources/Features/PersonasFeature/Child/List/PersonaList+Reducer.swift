import FeaturePrelude

// MARK: - PersonaList
public struct PersonaList: Sendable, ReducerProtocol {
	public init() {}
}

extension PersonaList {
	public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.createNewPersonaButtonTapped)):
			return .send(.delegate(.createNewPersona))

		case .delegate:
			return .none

		case .child:
			// TODO: implement
			return .none
		}
	}
}

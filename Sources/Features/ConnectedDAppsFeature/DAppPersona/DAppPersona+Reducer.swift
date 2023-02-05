import FeaturePrelude

// MARK: - Reducer

public struct DAppPersona: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>
	
	public init() { }

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		}
	}
}

// MARK: - State

public extension DAppPersona {
	struct State: Sendable, Hashable {
		let persona: String
		
		public init(persona: String) {
			self.persona = persona
		}
	}
}

// MARK: - Action

public extension DAppPersona {
	enum ViewAction: Sendable, Equatable {
		case appeared
	}
}

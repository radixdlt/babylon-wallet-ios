import FeaturePrelude

// MARK: - CreateAuthKey
public struct CreateAuthKey: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let entity: EntityPotentiallyVirtual
		public init(entity: EntityPotentiallyVirtual) {
			self.entity = entity
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum DelegateAction: Sendable, Equatable {
		case done(success: Bool)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		}
	}
}

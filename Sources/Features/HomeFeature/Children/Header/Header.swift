import FeaturePrelude

public struct Header: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var accountRecoveryIsNeeded: Bool

		public init(accountRecoveryIsNeeded: Bool) {
			self.accountRecoveryIsNeeded = accountRecoveryIsNeeded
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case settingsButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case displaySettings
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .settingsButtonTapped:
			return .send(.delegate(.displaySettings))
		}
	}
}

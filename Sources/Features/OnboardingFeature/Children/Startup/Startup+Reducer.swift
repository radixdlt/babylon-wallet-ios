import FeaturePrelude
import OnboardingClient

public struct Startup: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {}

	public enum ViewAction: Sendable, Equatable {
		case selectedCreateFirstAccount
		case selectedLoadBackup
		case selectedImportProfile
	}

	public enum DelegateAction: Sendable, Equatable {
		case createFirstAccount
		case loadFromBackup
		case importProfile
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .selectedCreateFirstAccount:
			return .send(.delegate(.createFirstAccount))
		case .selectedLoadBackup:
			return .send(.delegate(.loadFromBackup))
		case .selectedImportProfile:
			return .send(.delegate(.importProfile))
		}
	}
}

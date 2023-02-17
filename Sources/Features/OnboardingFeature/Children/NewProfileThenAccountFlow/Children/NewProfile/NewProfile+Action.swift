import FeaturePrelude
import ProfileClient

// MARK: - NewProfile.Action
extension NewProfile {
	public enum Action: Sendable, Equatable {
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

extension NewProfile.Action {
	public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
}

// MARK: - NewProfile.Action.ViewAction
extension NewProfile.Action {
	public enum ViewAction: Sendable, Equatable {
		case appeared
	}
}

// MARK: - NewProfile.Action.InternalAction
extension NewProfile.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - NewProfile.Action.SystemAction
extension NewProfile.Action {
	public enum SystemAction: Sendable, Equatable {
		case createOnboardingWalletResult(TaskResult<OnboardingWallet>)
	}
}

// MARK: - NewProfile.Action.DelegateAction
extension NewProfile.Action {
	public enum DelegateAction: Sendable, Equatable {
		case criticalFailureCouldNotCreateProfile
		case createdOnboardingWallet(OnboardingWallet)
	}
}

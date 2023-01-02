import ComposableArchitecture
import CreateAccountFeature
import ImportProfileFeature

// MARK: - Onboarding.Action
public extension Onboarding {
	// MARK: Action
	enum Action: Sendable, Equatable {
		case importProfile(ImportProfile.Action)
		case createAccount(CreateAccount.Action)
	}
}

import ComposableArchitecture
import ImportProfileFeature
import CreateAccountFeature

// MARK: - Onboarding.Action
public extension Onboarding {
	// MARK: Action
        enum Action: Equatable {
                case importProfile(ImportProfile.Action)
                case createAccount(CreateAccount.Action)
        }
}

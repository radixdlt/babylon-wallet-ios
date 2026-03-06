import Sargon

// MARK: - OnboardingClient
struct OnboardingClient {
	var loadProfileState: LoadProfileState
	var createNewProfile: CreateNewProfile
	var finishOnboardingWithRecoveredAccountAndBDFS: FinishOnboardingWithRecoveredAccountsAndBDFS
}

extension OnboardingClient {
	typealias LoadProfileState = @Sendable () async throws -> ProfileState
	typealias CreateNewProfile = @Sendable () async throws -> Void

	typealias FinishOnboardingWithRecoveredAccountsAndBDFS = @Sendable (AccountsRecoveredFromScanningUsingMnemonic) async throws -> Void
}

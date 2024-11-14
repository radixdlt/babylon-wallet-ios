import Sargon

// MARK: - OnboardingClient
struct OnboardingClient: Sendable {
	var loadProfileState: LoadProfileState
	var createNewProfile: CreateNewProfile
	var finishOnboardingWithRecoveredAccountAndBDFS: FinishOnboardingWithRecoveredAccountsAndBDFS

	init(
		loadProfileState: @escaping LoadProfileState,
		createNewProfile: @escaping CreateNewProfile,
		finishOnboardingWithRecoveredAccountAndBDFS: @escaping FinishOnboardingWithRecoveredAccountsAndBDFS
	) {
		self.loadProfileState = loadProfileState
		self.createNewProfile = createNewProfile
		self.finishOnboardingWithRecoveredAccountAndBDFS = finishOnboardingWithRecoveredAccountAndBDFS
	}
}

extension OnboardingClient {
	typealias LoadProfileState = @Sendable () async throws -> ProfileState
	typealias CreateNewProfile = @Sendable () async throws -> Void

	typealias FinishOnboardingWithRecoveredAccountsAndBDFS = @Sendable (AccountsRecoveredFromScanningUsingMnemonic) async throws -> Void
}

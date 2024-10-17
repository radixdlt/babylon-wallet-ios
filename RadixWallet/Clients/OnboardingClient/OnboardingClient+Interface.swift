import Sargon

// MARK: - OnboardingClient
struct OnboardingClient: Sendable {
	var loadProfile: LoadProfile
	var finishOnboarding: FinishOnboarding
	var finishOnboardingWithRecoveredAccountAndBDFS: FinishOnboardingWithRecoveredAccountsAndBDFS

	init(
		loadProfile: @escaping LoadProfile,
		finishOnboarding: @escaping FinishOnboarding,
		finishOnboardingWithRecoveredAccountAndBDFS: @escaping FinishOnboardingWithRecoveredAccountsAndBDFS
	) {
		self.loadProfile = loadProfile
		self.finishOnboarding = finishOnboarding
		self.finishOnboardingWithRecoveredAccountAndBDFS = finishOnboardingWithRecoveredAccountAndBDFS
	}
}

extension OnboardingClient {
	typealias LoadProfile = @Sendable () async -> Profile

	typealias FinishOnboarding = @Sendable () async -> EqVoid
	typealias FinishOnboardingWithRecoveredAccountsAndBDFS = @Sendable (AccountsRecoveredFromScanningUsingMnemonic) async throws -> EqVoid
}

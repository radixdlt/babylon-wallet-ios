import Sargon

// MARK: - OnboardingClient
public struct OnboardingClient: Sendable {
	public var loadProfileState: LoadProfileState
	public var finishOnboarding: FinishOnboarding
	public var finishOnboardingWithRecoveredAccountAndBDFS: FinishOnboardingWithRecoveredAccountsAndBDFS

	public init(
		loadProfileState: @escaping LoadProfileState,
		finishOnboarding: @escaping FinishOnboarding,
		finishOnboardingWithRecoveredAccountAndBDFS: @escaping FinishOnboardingWithRecoveredAccountsAndBDFS
	) {
		self.loadProfileState = loadProfileState
		self.finishOnboarding = finishOnboarding
		self.finishOnboardingWithRecoveredAccountAndBDFS = finishOnboardingWithRecoveredAccountAndBDFS
	}
}

extension OnboardingClient {
	public typealias LoadProfileState = @Sendable () async -> ProfileState

	public typealias FinishOnboarding = @Sendable () async -> EqVoid
	public typealias FinishOnboardingWithRecoveredAccountsAndBDFS = @Sendable (AccountsRecoveredFromScanningUsingMnemonic) async throws -> EqVoid
}

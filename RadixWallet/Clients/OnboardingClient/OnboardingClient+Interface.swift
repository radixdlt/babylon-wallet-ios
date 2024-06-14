import Sargon

// MARK: - OnboardingClient
public struct OnboardingClient: Sendable {
	public var loadProfile: LoadProfile
	public var finishOnboarding: FinishOnboarding
	public var finishOnboardingWithRecoveredAccountAndBDFS: FinishOnboardingWithRecoveredAccountsAndBDFS

	public init(
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
	public typealias LoadProfile = @Sendable () async -> Profile

	public typealias FinishOnboarding = @Sendable () async -> EqVoid
	public typealias FinishOnboardingWithRecoveredAccountsAndBDFS = @Sendable (AccountsRecoveredFromScanningUsingMnemonic) async throws -> EqVoid
}

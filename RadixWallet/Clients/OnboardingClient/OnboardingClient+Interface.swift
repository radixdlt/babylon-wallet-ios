import Sargon

// MARK: - OnboardingClient
public struct OnboardingClient: Sendable {
	public var loadProfileState: LoadProfileState
	public var createNewProfile: CreateNewProfile
	public var finishOnboardingWithRecoveredAccountAndBDFS: FinishOnboardingWithRecoveredAccountsAndBDFS

	public init(
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
	public typealias LoadProfileState = @Sendable () async -> ProfileState
	public typealias CreateNewProfile = @Sendable () async throws -> Void

	public typealias FinishOnboardingWithRecoveredAccountsAndBDFS = @Sendable (AccountsRecoveredFromScanningUsingMnemonic) async throws -> Void
}

import Sargon

// MARK: - OnboardingClient
public struct OnboardingClient: Sendable {
	public var loadProfileState: LoadProfileState
	public var createNewWallet: CreateNewWallet
	public var finishOnboardingWithRecoveredAccountAndBDFS: FinishOnboardingWithRecoveredAccountsAndBDFS

	public init(
		loadProfileState: @escaping LoadProfileState,
		createNewWallet: @escaping CreateNewWallet,
		finishOnboardingWithRecoveredAccountAndBDFS: @escaping FinishOnboardingWithRecoveredAccountsAndBDFS
	) {
		self.loadProfileState = loadProfileState
		self.createNewWallet = createNewWallet
		self.finishOnboardingWithRecoveredAccountAndBDFS = finishOnboardingWithRecoveredAccountAndBDFS
	}
}

extension OnboardingClient {
	public typealias LoadProfileState = @Sendable () async -> ProfileState
	public typealias CreateNewWallet = @Sendable () async throws -> Void

	public typealias FinishOnboardingWithRecoveredAccountsAndBDFS = @Sendable (AccountsRecoveredFromScanningUsingMnemonic) async throws -> Void
}

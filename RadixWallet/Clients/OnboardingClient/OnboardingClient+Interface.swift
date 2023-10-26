// MARK: - OnboardingClient
public struct OnboardingClient: Sendable {
	/// Call this when user has finished authentication from lock screen (e.g. Splash)
	public var unlockApp: UnlockApp // FIXME: Move to a new Lock/Unlock client?

	public var loadProfile: LoadProfile
	public var finishOnboarding: FinishOnboarding

	public init(
		unlockApp: @escaping UnlockApp,
		loadProfile: @escaping LoadProfile,
		finishOnboarding: @escaping FinishOnboarding
	) {
		self.unlockApp = unlockApp
		self.loadProfile = loadProfile
		self.finishOnboarding = finishOnboarding
	}
}

extension OnboardingClient {
	public typealias LoadProfile = @Sendable () async -> Profile

	public typealias FinishOnboarding = @Sendable () async -> EqVoid

	/// This might return a NEW profile if user did press DELETE conflicting
	/// profile during Ownership conflict resultion alert...
	public typealias UnlockApp = @Sendable () async -> Profile
}

// MARK: - OnboardingClient
public struct OnboardingClient: Sendable {
	/// Call this when user has finished authentication from lock screen (e.g. Splash)
	public var unlockedApp: UnlockedApp // FIXME: Move to a new Lock/Unlock client?

	public var loadProfile: LoadProfile
	public var finishedOnboarding: FinishedOnboarding

	public init(
		unlockedApp: @escaping UnlockedApp,
		loadProfile: @escaping LoadProfile,
		finishedOnboarding: @escaping FinishedOnboarding
	) {
		self.unlockedApp = unlockedApp
		self.loadProfile = loadProfile
		self.finishedOnboarding = finishedOnboarding
	}
}

extension OnboardingClient {
	public typealias LoadProfile = @Sendable () async -> Profile

	public typealias FinishedOnboarding = @Sendable () async -> EqVoid

	public typealias UnlockedApp = @Sendable () async -> Void
}

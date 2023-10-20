// MARK: - OnboardingClient
public struct OnboardingClient: Sendable {
	public var loadProfile: LoadProfile

	public var finishedOnboarding: FinishedOnboarding

	public init(
		loadProfile: @escaping LoadProfile,
		finishedOnboarding: @escaping FinishedOnboarding
	) {
		self.loadProfile = loadProfile
		self.finishedOnboarding = finishedOnboarding
	}
}

extension OnboardingClient {
	public typealias LoadProfile = @Sendable () async -> Profile

	public typealias FinishedOnboarding = @Sendable () async throws -> EqVoid
}

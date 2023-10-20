// MARK: - OnboardingClient
public struct OnboardingClient: Sendable {
	public var loadProfile: LoadProfile

	public var finishedOnboarding: FinishedOnboarding
	public var conflictingDeviceUsages: ConflictingDeviceUsages

	public init(
		loadProfile: @escaping LoadProfile,
		finishedOnboarding: @escaping FinishedOnboarding,
		conflictingDeviceUsages: @escaping ConflictingDeviceUsages
	) {
		self.loadProfile = loadProfile
		self.finishedOnboarding = finishedOnboarding
		self.conflictingDeviceUsages = conflictingDeviceUsages
	}
}

extension OnboardingClient {
	public typealias LoadProfile = @Sendable () async -> Profile

	public typealias FinishedOnboarding = @Sendable () async -> EqVoid
	public typealias ConflictingDeviceUsages = @Sendable () async -> AnyAsyncSequence<OwnershipConflict>
}

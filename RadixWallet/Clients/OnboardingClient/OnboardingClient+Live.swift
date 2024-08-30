
extension OnboardingClient: DependencyKey {
	public typealias Value = OnboardingClient

	public static let liveValue = Self.live()

	public static func live() -> Self {
		Self(
			loadProfile: {
				await ProfileStore.shared.profileSequence
			},
			finishOnboarding: {
				await ProfileStore.shared.finishedOnboarding()
				return EqVoid.instance
			},
			finishOnboardingWithRecoveredAccountAndBDFS: {
				try await ProfileStore.shared.finishOnboarding(with: $0)
				return EqVoid.instance
			}
		)
	}
}

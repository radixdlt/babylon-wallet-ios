
extension OnboardingClient: DependencyKey {
	typealias Value = OnboardingClient

	static let liveValue = Self.live()

	static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		Self(
			loadProfile: {
				await profileStore.profile
			},
			finishOnboarding: {
				await profileStore.finishedOnboarding()
				return EqVoid.instance
			},
			finishOnboardingWithRecoveredAccountAndBDFS: {
				try await profileStore.finishOnboarding(with: $0)
				return EqVoid.instance
			}
		)
	}
}

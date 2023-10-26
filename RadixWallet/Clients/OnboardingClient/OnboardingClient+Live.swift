
extension OnboardingClient: DependencyKey {
	public typealias Value = OnboardingClient

	public static let liveValue = Self.live()

	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		Self(
			unlockApp: {
				await profileStore.unlockedApp()
			},
			loadProfile: {
				await profileStore.profile
			},
			finishOnboarding: {
				await profileStore.finishedOnboarding()
				return EqVoid.instance
			}
		)
	}
}

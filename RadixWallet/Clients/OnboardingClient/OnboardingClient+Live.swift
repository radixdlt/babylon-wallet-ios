
extension OnboardingClient: DependencyKey {
	public typealias Value = OnboardingClient

	public static let liveValue = Self.live()

	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		Self(
			unlockedApp: {
				await profileStore.unlockedApp()
			},
			loadProfile: {
				await profileStore.profile
			},
			finishedOnboarding: {
				await profileStore.finishedOnboarding()
				return EqVoid.instance
			}
		)
	}
}

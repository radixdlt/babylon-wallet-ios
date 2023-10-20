
extension OnboardingClient: DependencyKey {
	public typealias Value = OnboardingClient

	public static let liveValue = Self.live()

	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		Self(
			loadProfile: {
				await profileStore.profile
			},
			finishedOnboarding: {
//				try await profileStore.commitEphemeral()
//				return EqVoid.instance
				fatalError()
			}
		)
	}
}

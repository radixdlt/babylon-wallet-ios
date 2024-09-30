
extension OnboardingClient: DependencyKey {
	public typealias Value = OnboardingClient

	public static let liveValue = Self.live()

	public static func live(profileStore: ProfileStore = .shared) -> Self {
		Self(
			loadProfileState: {
				await profileStore.profileState()
			},
			createNewProfile: {
				try await profileStore.createNewProfile()
			},
			finishOnboardingWithRecoveredAccountAndBDFS: {
				try await profileStore.finishOnboarding(with: $0)
			}
		)
	}
}

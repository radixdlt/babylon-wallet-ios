
extension OnboardingClient: DependencyKey {
	typealias Value = OnboardingClient

	static let liveValue = Self.live()

	static func live(profileStore: ProfileStore = .shared) -> Self {
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

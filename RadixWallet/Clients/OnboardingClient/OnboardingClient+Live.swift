
extension OnboardingClient: DependencyKey {
	public typealias Value = OnboardingClient

	public static let liveValue = Self.live()

	public static func live(profileStore: ProfileStore = .shared) -> Self {
		Self(
			loadProfileState: {
				await profileStore.profileState()
			},
			createNewWallet: {
				try await profileStore.createNewWallet()
			},
			finishOnboardingWithRecoveredAccountAndBDFS: {
				try await profileStore.finishOnboarding(with: $0)
			}
		)
	}
}

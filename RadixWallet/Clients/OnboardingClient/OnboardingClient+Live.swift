
extension OnboardingClient: DependencyKey {
	public typealias Value = OnboardingClient

	public static let liveValue = Self.live()

	public static func live(profileStore: ProfileStore = .shared) -> Self {
		Self(
			loadProfileState: {
				try! await profileStore.profileState().first()
			},
			createNewWallet: {
				try await profileStore.newProfile()
			},
			finishOnboardingWithRecoveredAccountAndBDFS: {
				try await profileStore.finishOnboarding(with: $0)
				return EqVoid.instance
			}
		)
	}
}

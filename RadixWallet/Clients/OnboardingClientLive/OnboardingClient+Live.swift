
extension OnboardingClient: DependencyKey {
	public typealias Value = OnboardingClient

	public static let liveValue = Self.live()

	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		Self(
			loadProfile: {
//				await getProfileStore().getLoadProfileOutcome()
				fatalError()
			},
			commitEphemeral: {
//				try await getProfileStore().commitEphemeral()
//				return EqVoid.instance
				fatalError()
			}
		)
	}
}

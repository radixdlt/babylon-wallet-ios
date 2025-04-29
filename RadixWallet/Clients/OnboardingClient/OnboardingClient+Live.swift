import FirebaseCrashlytics

extension OnboardingClient: DependencyKey {
	typealias Value = OnboardingClient

	static let liveValue = Self.live()

	static func live(profileStore: ProfileStore = .shared) -> Self {
		Self(
			loadProfileState: {
				Crashlytics.crashlytics().log("Loading profile")
				do {
					return try await profileStore.profileStateSequence().first()
				} catch {
					Crashlytics.crashlytics().log("Failed to load profile \(error)")
					throw error
				}
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

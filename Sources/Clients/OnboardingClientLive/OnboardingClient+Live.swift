import ClientPrelude
import FactorSourcesClient
import OnboardingClient
import ProfileStore

extension OnboardingClient: DependencyKey {
	public typealias Value = OnboardingClient

	public static let liveValue = Self.live()

	public static func live(
		profileStore getProfileStore: @escaping @Sendable () async -> ProfileStore = { await .shared }
	) -> Self {
		Self(
			loadProfile: {
				await getProfileStore().getLoadProfileOutcome()
			},
			commitEphemeral: {
				try await getProfileStore().commitEphemeral()
				return Prelude.Unit.instance
			}
		)
	}
}

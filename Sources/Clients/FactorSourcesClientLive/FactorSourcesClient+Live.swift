import ClientPrelude
import FactorSourcesClient
import ProfileStore

extension FactorSourcesClient: DependencyKey {
	public typealias Value = FactorSourcesClient

	public static func live(profileStore: ProfileStore = .shared) -> Self {
		Self(
			getFactorSources: {
				await profileStore.profile.factorSources
			}
		)
	}

	public static let liveValue = Self.live()
}

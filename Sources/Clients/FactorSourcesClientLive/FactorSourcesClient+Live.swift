import ClientPrelude
import FactorSourcesClient
import ProfileStore

extension FactorSourcesClient: DependencyKey {
	public typealias Value = FactorSourcesClient

	public static func live(
		profileStore getProfileStore: @escaping @Sendable () async -> ProfileStore = { await ProfileStore.shared() }
	) -> Self {
		Self(
			getFactorSources: {
				await getProfileStore().profile.factorSources
			}
		)
	}

	public static let liveValue = Self.live()
}

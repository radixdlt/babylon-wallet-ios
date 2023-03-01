import ClientPrelude
import PersonasClient
import ProfileStore

extension PersonasClient: DependencyKey {
	public typealias Value = PersonasClient

	public static func live(profileStore: ProfileStore = .shared) -> Self {
		Self(
			getPersonas: {
				await profileStore.network.personas
			}
		)
	}

	public static let liveValue = Self.live()
}

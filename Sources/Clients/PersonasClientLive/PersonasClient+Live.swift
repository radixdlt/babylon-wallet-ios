import ClientPrelude
import PersonasClient
import ProfileStore

extension PersonasClient: DependencyKey {
	public typealias Value = PersonasClient

	public static func live(profileStore: ProfileStore = .shared) -> Self {
		Self(
			getPersonas: {
				await profileStore.network.personas
			},
			saveVirtualPersona: { persona in
				try await profileStore.updating {
					try $0.addPersona(persona)
				}
			}
		)
	}

	public static let liveValue = Self.live()
}

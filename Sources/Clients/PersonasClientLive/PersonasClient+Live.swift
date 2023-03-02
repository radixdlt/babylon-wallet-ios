import ClientPrelude
import PersonasClient
import ProfileStore

extension PersonasClient: DependencyKey {
	public typealias Value = PersonasClient

	public static func live(profileStore: ProfileStore = .shared) -> Self {
		Self(
			getPersonas: {
				guard let network = await profileStore.network else {
					return .init()
				}
				return network.personas
			},
			createUnsavedVirtualPersona: { request in
				try await profileStore.profile.createNewUnsavedVirtualEntity(request: request)
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

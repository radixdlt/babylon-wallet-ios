import ClientPrelude
import PersonasClient
import ProfileStore

extension PersonasClient: DependencyKey {
	public typealias Value = PersonasClient

	public static func live(
		profileStore getProfileStore: @escaping @Sendable () async -> ProfileStore = { await .shared }
	) -> Self {
		Self(
			getPersonas: {
				guard let network = await getProfileStore().network else {
					return .init()
				}
				return network.personas
			},
			updatePersona: { persona in
				try await getProfileStore().updating {
					try $0.updatePersona(persona)
				}
			},
			createUnsavedVirtualPersona: { request in
				try await getProfileStore().profile.createNewUnsavedVirtualEntity(request: request)
			},
			saveVirtualPersona: { persona in
				try await getProfileStore().updating {
					try $0.addPersona(persona)
				}
			},
			hasAnyPersonaOnAnyNetwork: {
				// FIXME: !!! stop using hard coding!
				loggerGlobal.critical("BEFORE RELEASE STOP HARDCODING for 'isFirstPersonaOnAnyNetwork'")
				return false
//				await getProfileStore().profile.hasAnyPersonaOnAnyNetwork()
			}
		)
	}

	public static let liveValue = Self.live()
}

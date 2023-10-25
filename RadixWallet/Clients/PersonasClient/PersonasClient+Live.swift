
extension PersonasClient: DependencyKey {
	public typealias Value = PersonasClient

	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		let getPersonasOnNetwork: GetPersonasOnNetwork = { networkID in
			guard let network = try? await profileStore.profile.network(id: networkID) else {
				return .init()
			}
			return network.getPersonas()
		}

		return Self(
			personas: {
				await profileStore.personaValues()
			},
			nextPersonaIndex: { maybeNetworkID async -> HD.Path.Component.Child.Value in
				let currentNetworkID = await profileStore.profile.networkID
				let networkID = maybeNetworkID ?? currentNetworkID
				let count = await (try? profileStore.profile.network(id: networkID).nextPersonaIndex()) ?? 0
				return HD.Path.Component.Child.Value(count)
			},
			getPersonas: {
				guard let network = await profileStore.network else {
					return .init()
				}
				return network.getPersonas()
			},
			getPersonasOnNetwork: getPersonasOnNetwork,
			updatePersona: { persona in
				try await profileStore.updating {
					try $0.updatePersona(persona)
				}
			},
			saveVirtualPersona: { persona in
				try await profileStore.updating {
					try $0.addPersona(persona)
				}
			},
			hasAnyPersonaOnAnyNetwork: {
				await profileStore.profile.hasAnyPersonaOnAnyNetwork()
			},
			hasAnyPersonaOnCurrentNetwork: {
				await profileStore.profile.network?.hasAnyPersona() ?? false
			}
		)
	}

	public static let liveValue = Self.live()
}

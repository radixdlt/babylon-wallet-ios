
extension PersonasClient: DependencyKey {
	public typealias Value = PersonasClient

	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		let getPersonasOnNetwork: GetPersonasOnNetwork = { networkID in
			guard let network = try? await profileStore.profile.network(id: networkID) else {
				return .init()
			}
			return network.personas
		}

		return Self(
			personas: {
				await profileStore.personaValues()
			},
			nextPersonaIndex: { maybeNextworkID async -> HD.Path.Component.Child.Value in
				let currentNetworkID = await profileStore.profile.networkID
				let networkID = maybeNextworkID ?? currentNetworkID
				return await HD.Path.Component.Child.Value(getPersonasOnNetwork(networkID).count)
			},
			getPersonas: {
				guard let network = await profileStore.network else {
					return .init()
				}
				return network.personas
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
			}
		)
	}

	public static let liveValue = Self.live()
}


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
			nextPersonaIndexForFactorSource: { _, maybeNetworkID async -> HD.Path.Component.Child.Value in
				let currentNetworkID = await profileStore.profile.networkID
				let networkID = maybeNetworkID ?? currentNetworkID
				let maybeNetwork: Profile.Network? = try? await profileStore.profile.network(id: networkID)
				if let network = maybeNetwork {
					fatalError("IMPL ME NOW")
				} else {
					// First Persona on this network
					return 0
				}
			},
			getPersonas: {
				try await profileStore.network().getPersonas()
			},
			getPersonasOnNetwork: getPersonasOnNetwork,
			getHiddenPersonasOnCurrentNetwork: {
				try await profileStore.network().getHiddenPersonas()
			},
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
			hasSomePersonaOnAnyNetwork: {
				await profileStore.profile.hasAnyPersonaOnAnyNetwork()
			},
			hasSomePersonaOnCurrentNetwork: {
				await profileStore.profile.network?.hasSomePersona() ?? false
			}
		)
	}

	public static let liveValue = Self.live()
}


extension PersonasClient: DependencyKey {
	public typealias Value = PersonasClient

	public static func live(
		profileStore getProfileStore: @escaping @Sendable () async -> ProfileStore = { await .shared }
	) -> Self {
		let getPersonasOnNetwork: GetPersonasOnNetwork = { networkID in
			guard let network = try? await getProfileStore().profile.network(id: networkID) else {
				return .init()
			}
			return network.personas
		}

		return Self(
			personas: {
				await getProfileStore().personaValues()
			},
			nextPersonaIndex: { maybeNextworkID async -> HD.Path.Component.Child.Value in
				let currentNetworkID = await getProfileStore().profile.networkID
				let networkID = maybeNextworkID ?? currentNetworkID
				return await HD.Path.Component.Child.Value(getPersonasOnNetwork(networkID).count)
			},
			getPersonas: {
				guard let network = await getProfileStore().network else {
					return .init()
				}
				return network.personas
			},
			getPersonasOnNetwork: getPersonasOnNetwork,
			updatePersona: { persona in
				try await getProfileStore().updating {
					try $0.updatePersona(persona)
				}
			},
			saveVirtualPersona: { persona in
				try await getProfileStore().updating {
					try $0.addPersona(persona)
				}
			},
			hasAnyPersonaOnAnyNetwork: {
				await getProfileStore().profile.hasAnyPersonaOnAnyNetwork()
			}
		)
	}

	public static let liveValue = Self.live()
}

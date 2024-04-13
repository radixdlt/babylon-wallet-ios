
extension PersonasClient: DependencyKey {
	public typealias Value = PersonasClient

	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		let getPersonasOnNetwork: GetPersonasOnNetwork = { _ in
//			guard let network = try? await profileStore.profile.network(id: networkID) else {
//				return .init()
//			}
//			return network.getPersonas()
			sargonProfileFinishMigrateAtEndOfStage1()
		}

		return Self(
			personas: {
				await profileStore.personaValues()
			},
			getPersonas: {
//				try await profileStore.network().getPersonas()
				sargonProfileFinishMigrateAtEndOfStage1()
			},
			getPersonasOnNetwork: getPersonasOnNetwork,
			getHiddenPersonasOnCurrentNetwork: {
//				try await profileStore.network().getHiddenPersonas()
				sargonProfileFinishMigrateAtEndOfStage1()
			},
			updatePersona: { _ in
//				try await profileStore.updating {
//					try $0.updatePersona(persona)
//				}
				sargonProfileFinishMigrateAtEndOfStage1()
			},
			saveVirtualPersona: { _ in
//				try await profileStore.updating {
//					try $0.addPersona(persona)
//				}
				sargonProfileFinishMigrateAtEndOfStage1()
			},
			hasSomePersonaOnAnyNetwork: {
//				await profileStore.profile.hasAnyPersonaOnAnyNetwork()
				sargonProfileFinishMigrateAtEndOfStage1()
			},
			hasSomePersonaOnCurrentNetwork: {
//				await profileStore.profile.network?.hasSomePersona() ?? false
				sargonProfileFinishMigrateAtEndOfStage1()
			}
		)
	}

	public static let liveValue = Self.live()
}

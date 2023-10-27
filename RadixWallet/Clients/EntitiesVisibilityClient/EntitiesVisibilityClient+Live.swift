extension EntitiesVisibilityClient: DependencyKey {
	public typealias Value = EntitiesVisibilityClient

	public static let liveValue: Self = .live()

	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		.init(
			hideAccount: { account in
				try await profileStore.updatingOnCurrentNetwork { network in
					network.hideAccount(account)
				}
			},
			hidePersona: { persona in
				try await profileStore.updatingOnCurrentNetwork { network in
					network.hidePersona(persona)
				}
			},
			unhideAllEntities: {
				try await profileStore.updatingOnCurrentNetwork { network in
					network.unhideAllEntities()
				}
			},
			getHiddenEntitiesStats: {
				let network = try await profileStore.network()

				return .init(
					hiddenAccountsCount: network.getHiddenAccounts().count,
					hiddenPersonasCount: network.getHiddenPersonas().count
				)
			}
		)
	}
}

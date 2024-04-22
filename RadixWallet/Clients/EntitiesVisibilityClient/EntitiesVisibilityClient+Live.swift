extension EntitiesVisibilityClient: DependencyKey {
	public typealias Value = EntitiesVisibilityClient

	public static let liveValue: Self = .live()

	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		.init(
			hideAccounts: { idsOfAccounts in
				try await profileStore.updatingOnCurrentNetwork { network in
					network.hideAccounts(ids: idsOfAccounts)
				}
			},
			hidePersonas: { idsOfPersonas in
				try await profileStore.updatingOnCurrentNetwork { network in
					network.hidePersonas(ids: idsOfPersonas)
				}
			},
			unhideAllEntities: {
				try await profileStore.updatingOnCurrentNetwork { network in
					network.unhideAllEntities()
				}
			},
			getHiddenEntityCounts: {
				let network = try await profileStore.network()

				return .init(
					hiddenAccountsCount: network.getHiddenAccounts().count,
					hiddenPersonasCount: network.getHiddenPersonas().count
				)
			}
		)
	}
}

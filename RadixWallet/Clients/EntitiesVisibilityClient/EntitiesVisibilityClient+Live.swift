extension EntitiesVisibilityClient: DependencyKey {
	public typealias Value = EntitiesVisibilityClient

	public static let liveValue: Self = .live()

	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		.init(
			hideAccounts: { _ in
//				try await profileStore.updatingOnCurrentNetwork { network in
//					network.hideAccounts(ids: idsOfAccounts)
//				}
				sargonProfileFinishMigrateAtEndOfStage1()
			},
			hidePersonas: { _ in
//				try await profileStore.updatingOnCurrentNetwork { network in
//					network.hidePersonas(ids: idsOfPersonas)
//				}
				sargonProfileFinishMigrateAtEndOfStage1()
			},
			unhideAllEntities: {
//				try await profileStore.updatingOnCurrentNetwork { network in
//					network.unhideAllEntities()
//				}
				sargonProfileFinishMigrateAtEndOfStage1()
			},
			getHiddenEntityCounts: {
//				let network = try await profileStore.network()
//
//				return .init(
//					hiddenAccountsCount: network.getHiddenAccounts().count,
//					hiddenPersonasCount: network.getHiddenPersonas().count
//				)
				sargonProfileFinishMigrateAtEndOfStage1()
			}
		)
	}
}

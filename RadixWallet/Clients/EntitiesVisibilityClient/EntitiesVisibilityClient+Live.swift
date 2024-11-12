extension EntitiesVisibilityClient: DependencyKey {
	typealias Value = EntitiesVisibilityClient

	static let liveValue: Self = .live()

	static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		.init(
			hideAccount: { id in
				try await profileStore.updatingOnCurrentNetwork { network in
					network.hideAccount(id: id)
				}
			},
			hidePersona: { id in
				try await profileStore.updatingOnCurrentNetwork { network in
					network.hidePersona(id: id)
				}
			},
			unhideAccount: { id in
				try await profileStore.updatingOnCurrentNetwork { network in
					network.unhideAccount(id: id)
				}
			},
			unhidePersona: { id in
				try await profileStore.updatingOnCurrentNetwork { network in
					network.unhidePersona(id: id)
				}
			},
			getHiddenEntities: {
				let network = try await profileStore.network()
				return .init(accounts: network.getHiddenAccounts(), personas: network.getHiddenPersonas())
			}
		)
	}
}

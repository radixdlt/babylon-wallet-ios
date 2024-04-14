
extension AuthorizedDappsClient: DependencyKey {
	public typealias Value = AuthorizedDappsClient

	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		Self(
			getAuthorizedDapps: {
//				guard let network = await profileStore.profile.network else {
//					return .init()
//				}
//				return network.authorizedDapps
				sargonProfileFinishMigrateAtEndOfStage1()
			},
			addAuthorizedDapp: { _ in
//				try await profileStore.updating {
//					_ = try $0.addAuthorizedDapp(newDapp)
//				}
				sargonProfileFinishMigrateAtEndOfStage1()
			},
			forgetAuthorizedDapp: { _, _ in
//				let currentNetworkID = await profileStore.profile.networkID
//				let networkID = maybeNetworkID ?? currentNetworkID
//				return try await profileStore.updating {
//					_ = try $0.forgetAuthorizedDapp(toForget, on: networkID)
//				}
				sargonProfileFinishMigrateAtEndOfStage1()
			},
			updateAuthorizedDapp: { _ in
//				try await profileStore.updating {
//					try $0.updateAuthorizedDapp(toUpdate)
//				}
				sargonProfileFinishMigrateAtEndOfStage1()
			},
			updateOrAddAuthorizedDapp: { _ in
//				try await profileStore.updating {
//					try $0.updateOrAddAuthorizedDapp(dapp)
//				}
				sargonProfileFinishMigrateAtEndOfStage1()
			},
			deauthorizePersonaFromDapp: { _, _, _ in
//				try await profileStore.updating {
//					try $0.deauthorizePersonaFromDapp(personaID, dAppID: authorizedDappID, networkID: networkID)
//				}
				sargonProfileFinishMigrateAtEndOfStage1()
			},
			detailsForAuthorizedDapp: { _ in
//				try await profileStore.profile.detailsForAuthorizedDapp(simple)
				sargonProfileFinishMigrateAtEndOfStage1()
			}
		)
	}

	public static let liveValue = Self.live()
}

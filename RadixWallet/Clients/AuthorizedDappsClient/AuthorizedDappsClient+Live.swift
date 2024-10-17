
extension AuthorizedDappsClient: DependencyKey {
	public typealias Value = AuthorizedDappsClient

	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		Self(
			getAuthorizedDapps: {
				guard let network = await profileStore.profile().network else {
					return .init()
				}
				return network.authorizedDapps.asIdentified()
			},
			authorizedDappValues: {
				await profileStore.authorizedDappValues()
			},
			addAuthorizedDapp: { newDapp in
				try await profileStore.updating {
					_ = try $0.addAuthorizedDapp(newDapp)
				}
			},
			forgetAuthorizedDapp: { toForget, maybeNetworkID in
				let currentNetworkID = await profileStore.profile().networkID
				let networkID = maybeNetworkID ?? currentNetworkID
				return try await profileStore.updating {
					_ = try $0.forgetAuthorizedDapp(toForget, on: networkID)
				}
			},
			updateAuthorizedDapp: { toUpdate in
				try await profileStore.updating {
					try $0.updateAuthorizedDapp(toUpdate)
				}
			},
			updateOrAddAuthorizedDapp: { dapp in
				try await profileStore.updating {
					try $0.updateOrAddAuthorizedDapp(dapp)
				}
			},
			deauthorizePersonaFromDapp: { personaID, authorizedDappID, networkID in
				try await profileStore.updating {
					try $0.deauthorizePersonaFromDapp(personaID, dAppID: authorizedDappID, networkID: networkID)
				}
			},
			detailsForAuthorizedDapp: { simple in
				try await profileStore.profile().detailsForAuthorizedDapp(simple)
			}
		)
	}

	public static let liveValue = Self.live()
}

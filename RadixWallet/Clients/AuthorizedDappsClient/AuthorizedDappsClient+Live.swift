
extension AuthorizedDappsClient: DependencyKey {
	public typealias Value = AuthorizedDappsClient

	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		Self(
			getAuthorizedDapps: {
				guard let network = await profileStore.network else {
					return .init()
				}
				let accountsOnNetwork = network.accounts.nonHidden
				return network.authorizedDapps.map { dapp in
					var dapp = dapp
					for persona in dapp.referencesToAuthorizedPersonas {
						if let sharedAccounts = persona.sharedAccounts {
							let ids = sharedAccounts.ids.filter { address in
								accountsOnNetwork.contains {
									$0.address == address
								}
							}
							dapp.referencesToAuthorizedPersonas[id: persona.id]?.sharedAccounts?.ids = ids
						}
					}
					return dapp
				}.asIdentifiable()
			},
			addAuthorizedDapp: { newDapp in
				try await profileStore.updating {
					_ = try $0.addAuthorizedDapp(newDapp)
				}
			},
			forgetAuthorizedDapp: { toForget, maybeNetworkID in
				let currentNetworkID = await profileStore.profile.networkID
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
				try await profileStore.profile.detailsForAuthorizedDapp(simple)
			}
		)
	}

	public static let liveValue = Self.live()
}

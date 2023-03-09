import AuthorizedDappsClient
import ClientPrelude
import ProfileStore

extension AuthorizedDappsClient: DependencyKey {
	public typealias Value = AuthorizedDappsClient

	public static func live(
		profileStore getProfileStore: @escaping @Sendable () async -> ProfileStore = { await .shared }
	) -> Self {
		Self(
			getAuthorizedDapps: {
				guard let network = await getProfileStore().network else {
					return .init()
				}
				return network.authorizedDapps
			},
			addAuthorizedDapp: { newDapp in
				try await getProfileStore().updating {
					_ = try $0.addAuthorizedDapp(newDapp)
				}
			},
			forgetAuthorizedDapp: { toForget, networkID in
				try await getProfileStore().updating {
					_ = try $0.forgetAuthorizedDapp(toForget, on: networkID)
				}
			},
			updateAuthorizedDapp: { toUpdate in
				try await getProfileStore().updating {
					try $0.updateAuthorizedDapp(toUpdate)
				}
			},
			updateOrAddAuthorizedDapp: { dapp in
				try await getProfileStore().updating {
					try $0.updateOrAddAuthorizedDapp(dapp)
				}
			},
			deauthorizePersonaFromDapp: { personaID, authorizedDappID, networkID in
				try await getProfileStore().updating {
					try $0.deauthorizePersonaFromDapp(personaID, dAppID: authorizedDappID, networkID: networkID)
				}
			},
			detailsForAuthorizedDapp: { simple in
				try await getProfileStore().profile.detailsForAuthorizedDapp(simple)
			}
		)
	}

	public static let liveValue = Self.live()
}

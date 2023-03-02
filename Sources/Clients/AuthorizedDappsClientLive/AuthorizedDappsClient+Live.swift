import AuthorizedDappsClient
import ClientPrelude
import ProfileStore

extension AuthorizedDappsClient: DependencyKey {
	public typealias Value = AuthorizedDappsClient

	public static func live(profileStore: ProfileStore = .shared) -> Self {
		Self(
			getAuthorizedDapps: {
				await profileStore.network.authorizedDapps
			},
			addAuthorizedDapp: { newDapp in
				try await profileStore.updating {
					_ = try $0.addAuthorizedDapp(newDapp)
				}
			},
			forgetAuthorizedDapp: { toForget, networkID in
				try await profileStore.updating {
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
			disconnectPersonaFromDapp: { personaID, authorizedDappID, networkID in
				try await profileStore.updating {
					try $0.disconnectPersonaFromDapp(personaID, dAppID: authorizedDappID, networkID: networkID)
				}
			},
			detailsForAuthorizedDapp: { simple in
				try await profileStore.profile.detailsForAuthorizedDapp(simple)
			}
		)
	}

	public static let liveValue = Self.live()
}

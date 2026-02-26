import Sargon

// MARK: - P2PTransportProfilesClient + DependencyKey
extension P2PTransportProfilesClient: DependencyKey {
	typealias Value = P2PTransportProfilesClient

	static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		@Dependency(\.appPreferencesClient) var appPreferencesClient

		return Self(
			p2pTransportProfilesValues: {
				await profileStore.appPreferencesValues()
					.map(\.p2pTransportProfiles)
					.eraseToAnyAsyncSequence()
			},
			getCurrentProfile: {
				await appPreferencesClient.getPreferences().p2pTransportProfiles.current
			},
			getAllProfiles: {
				await appPreferencesClient.getPreferences().p2pTransportProfiles.all
			},
			addProfile: { profile in
				try await appPreferencesClient.updating { appPreferences in
					var profiles = appPreferences.p2pTransportProfiles
					let inserted = profiles.append(profile)
					guard inserted else { return }
					appPreferences.p2pTransportProfiles = profiles
				}
			},
			removeProfile: { profile in
				try await appPreferencesClient.updating { appPreferences in
					var profiles = appPreferences.p2pTransportProfiles
					let removed = profiles.remove(profile)
					guard removed else { return }
					appPreferences.p2pTransportProfiles = profiles
				}
			},
			changeProfile: { profile in
				try await appPreferencesClient.updating { appPreferences in
					var profiles = appPreferences.p2pTransportProfiles
					let changed = profiles.changeCurrent(to: profile)
					guard changed else { return }
					appPreferences.p2pTransportProfiles = profiles
				}
			},
			hasProfileWithSignalingServerURL: { url in
				await appPreferencesClient
					.getPreferences()
					.hasP2PTransportProfile(withSignalingServer: url.url.absoluteString)
			}
		)
	}

	static let liveValue: Self = .live()
}

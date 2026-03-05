import Sargon

// MARK: - P2PTransportProfilesClient + DependencyKey
extension P2PTransportProfilesClient: DependencyKey {
	typealias Value = P2PTransportProfilesClient

	static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		Self(
			p2pTransportProfilesValues: {
				await profileStore.p2pTransportProfilesValues()
			},
			getProfiles: {
				try SargonOs.shared.p2pTransportProfiles()
			},
			getCurrentProfile: {
				try SargonOs.shared.p2pTransportProfiles().current
			},
			addProfile: { profile in
				try await SargonOs.shared.addP2pTransportProfile(profile: profile)
			},
			updateProfile: { profile in
				try await SargonOs.shared.updateP2pTransportProfile(updated: profile)
			},
			removeProfile: { profile in
				try await SargonOs.shared.deleteP2pTransportProfile(profile: profile)
			},
			changeProfile: { profile in
				try await SargonOs.shared.changeCurrentP2pTransportProfile(to: profile)
			},
			hasProfileWithSignalingServerURL: { signalingServerURL in
				try SargonOs.shared
					.p2pTransportProfiles()
					.all
					.contains(where: { $0.signalingServer == signalingServerURL })
			}
		)
	}

	static let liveValue: Self = .live()
}

import Sargon

extension P2PTransportProfilesClient: TestDependencyKey {
	static let previewValue = Self(
		p2pTransportProfilesValues: { AsyncLazySequence([.default]).eraseToAnyAsyncSequence() },
		getProfiles: { .default },
		getCurrentProfile: { SavedP2PTransportProfiles.default.current },
		addProfile: { _ in true },
		updateProfile: { _ in true },
		removeProfile: { _ in true },
		changeProfile: { _ in true },
		hasProfileWithSignalingServerURL: { _ in false }
	)

	static let testValue = Self(
		p2pTransportProfilesValues: unimplemented("\(Self.self).p2pTransportProfilesValues"),
		getProfiles: unimplemented("\(Self.self).getProfiles"),
		getCurrentProfile: unimplemented("\(Self.self).getCurrentProfile"),
		addProfile: unimplemented("\(Self.self).addProfile"),
		updateProfile: unimplemented("\(Self.self).updateProfile"),
		removeProfile: unimplemented("\(Self.self).removeProfile"),
		changeProfile: unimplemented("\(Self.self).changeProfile"),
		hasProfileWithSignalingServerURL: unimplemented("\(Self.self).hasProfileWithSignalingServerURL")
	)
}

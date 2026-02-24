import Sargon

extension P2PTransportProfilesClient: TestDependencyKey {
	static let previewValue = Self(
		p2pTransportProfilesValues: { AsyncLazySequence([.default]).eraseToAnyAsyncSequence() },
		getCurrentProfile: { SavedP2PTransportProfiles.default.current },
		getAllProfiles: { SavedP2PTransportProfiles.default.all },
		addProfile: { _ in },
		removeProfile: { _ in },
		changeProfile: { _ in },
		hasProfileWithSignalingServerURL: { _ in false }
	)

	static let testValue = Self(
		p2pTransportProfilesValues: unimplemented("\(Self.self).p2pTransportProfilesValues"),
		getCurrentProfile: unimplemented("\(Self.self).getCurrentProfile"),
		getAllProfiles: unimplemented("\(Self.self).getAllProfiles"),
		addProfile: unimplemented("\(Self.self).addProfile"),
		removeProfile: unimplemented("\(Self.self).removeProfile"),
		changeProfile: unimplemented("\(Self.self).changeProfile"),
		hasProfileWithSignalingServerURL: unimplemented("\(Self.self).hasProfileWithSignalingServerURL")
	)
}

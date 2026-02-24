import Sargon

// MARK: - P2PTransportProfilesClient
struct P2PTransportProfilesClient: Sendable {
	var p2pTransportProfilesValues: P2PTransportProfilesValues
	var getCurrentProfile: GetCurrentProfile
	var getAllProfiles: GetAllProfiles
	var addProfile: AddProfile
	var removeProfile: RemoveProfile
	var changeProfile: ChangeProfile
	var hasProfileWithSignalingServerURL: HasProfileWithSignalingServerURL
}

extension P2PTransportProfilesClient {
	typealias P2PTransportProfilesValues = @Sendable () async -> AnyAsyncSequence<SavedP2PTransportProfiles>
	typealias GetCurrentProfile = @Sendable () async -> P2PTransportProfile
	typealias GetAllProfiles = @Sendable () async -> [P2PTransportProfile]
	typealias AddProfile = @Sendable (P2PTransportProfile) async throws -> Void
	typealias RemoveProfile = @Sendable (P2PTransportProfile) async throws -> Void
	typealias ChangeProfile = @Sendable (P2PTransportProfile) async throws -> Void
	typealias HasProfileWithSignalingServerURL = @Sendable (FfiUrl) async -> Bool
}

extension DependencyValues {
	var p2pTransportProfilesClient: P2PTransportProfilesClient {
		get { self[P2PTransportProfilesClient.self] }
		set { self[P2PTransportProfilesClient.self] = newValue }
	}
}

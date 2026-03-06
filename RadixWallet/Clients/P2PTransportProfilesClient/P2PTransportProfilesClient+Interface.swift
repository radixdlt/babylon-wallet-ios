import Sargon

// MARK: - P2PTransportProfilesClient
struct P2PTransportProfilesClient {
	var p2pTransportProfilesValues: P2PTransportProfilesValues
	var getProfiles: GetProfiles
	var getCurrentProfile: GetCurrentProfile
	var addProfile: AddProfile
	var updateProfile: UpdateProfile
	var removeProfile: RemoveProfile
	var changeProfile: ChangeProfile
	var hasProfileWithSignalingServerURL: HasProfileWithSignalingServerURL
}

extension P2PTransportProfilesClient {
	typealias P2PTransportProfilesValues = @Sendable () async -> AnyAsyncSequence<SavedP2PTransportProfiles>
	typealias GetProfiles = @Sendable () async throws -> SavedP2PTransportProfiles
	typealias GetCurrentProfile = @Sendable () async throws -> P2PTransportProfile
	typealias AddProfile = @Sendable (P2PTransportProfile) async throws -> Bool
	typealias UpdateProfile = @Sendable (P2PTransportProfile) async throws -> Bool
	typealias RemoveProfile = @Sendable (P2PTransportProfile) async throws -> Bool
	typealias ChangeProfile = @Sendable (P2PTransportProfile) async throws -> Bool
	typealias HasProfileWithSignalingServerURL = @Sendable (String) async throws -> Bool
}

extension DependencyValues {
	var p2pTransportProfilesClient: P2PTransportProfilesClient {
		get { self[P2PTransportProfilesClient.self] }
		set { self[P2PTransportProfilesClient.self] = newValue }
	}
}

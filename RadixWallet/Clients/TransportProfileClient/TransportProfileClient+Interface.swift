import Sargon

typealias DeviceID = UUID

// MARK: - TransportProfileClient
struct TransportProfileClient {
	var importProfile: ImportProfile
	var profileForExport: ProfileForExport
	var didExportProfile: DidExportProfile
}

extension TransportProfileClient {
	typealias ImportProfile = @Sendable (Profile, Set<FactorSourceIDFromHash>, _ containsP2PLinks: Bool) async throws -> Void
	typealias ProfileForExport = @Sendable () async throws -> Profile
	typealias DidExportProfile = @Sendable (Profile) throws -> Void
}

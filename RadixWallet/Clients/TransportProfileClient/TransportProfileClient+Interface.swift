import Sargon

typealias DeviceID = UUID

// MARK: - TransportProfileClient
struct TransportProfileClient: Sendable {
	var importProfile: ImportProfile
	var profileForExport: ProfileForExport
	var didExportProfile: DidExportProfile

	init(
		importProfile: @escaping ImportProfile,
		profileForExport: @escaping ProfileForExport,
		didExportProfile: @escaping DidExportProfile
	) {
		self.importProfile = importProfile
		self.profileForExport = profileForExport
		self.didExportProfile = didExportProfile
	}
}

extension TransportProfileClient {
	typealias ImportProfile = @Sendable (Profile, Set<FactorSourceIDFromHash>, _ skippedMainBdfs: Bool, _ containsP2PLinks: Bool) async throws -> Void
	typealias ProfileForExport = @Sendable () async throws -> Profile
	typealias DidExportProfile = @Sendable (Profile) throws -> Void
}

import Sargon

public typealias DeviceID = UUID

// MARK: - TransportProfileClient
public struct TransportProfileClient: Sendable {
	public var importProfile: ImportProfile
	public var profileForExport: ProfileForExport
	public var didExportProfile: DidExportProfile

	public init(
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
	public typealias ImportProfile = @Sendable (Profile, Set<FactorSourceIDFromHash>, _ skippedMainBdfs: Bool, _ containsP2PLinks: Bool) async throws -> Void
	public typealias ProfileForExport = @Sendable () async throws -> Profile
	public typealias DidExportProfile = @Sendable (Profile) throws -> Void
}

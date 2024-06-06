import Sargon

public typealias DeviceID = UUID

// MARK: - TransportProfileClient
public struct TransportProfileClient: Sendable {
	public var importProfile: ImportProfile
	public var profileForExport: ProfileForExport
	public var didExportProfile: DidExportProfile
	public var loadDeviceID: LoadDeviceID

	public init(
		importProfile: @escaping ImportProfile,
		profileForExport: @escaping ProfileForExport,
		didExportProfile: @escaping DidExportProfile,
		loadDeviceID: @escaping LoadDeviceID
	) {
		self.importProfile = importProfile
		self.profileForExport = profileForExport
		self.didExportProfile = didExportProfile
		self.loadDeviceID = loadDeviceID
	}
}

extension TransportProfileClient {
	public typealias ImportProfile = @Sendable (Profile, Set<FactorSourceIDFromHash>, Bool) async throws -> Void
	public typealias ProfileForExport = @Sendable () async throws -> Profile
	public typealias DidExportProfile = @Sendable (Profile) throws -> Void
	public typealias LoadDeviceID = @Sendable () async -> UUID?
}

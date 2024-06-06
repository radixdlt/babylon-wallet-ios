import Sargon

public typealias DeviceID = UUID

// MARK: - BackupsClient
public struct BackupsClient: Sendable {
	public var snapshotOfProfileForExport: SnapshotOfProfileForExport
	public var loadProfileBackups: LoadProfileBackups
	public var importProfileSnapshot: ImportProfileSnapshot
	public var didExportProfileSnapshot: DidExportProfileSnapshot
	public var loadDeviceID: LoadDeviceID

	public init(
		snapshotOfProfileForExport: @escaping SnapshotOfProfileForExport,
		loadProfileBackups: @escaping LoadProfileBackups,
		importProfileSnapshot: @escaping ImportProfileSnapshot,
		didExportProfileSnapshot: @escaping DidExportProfileSnapshot,
		loadDeviceID: @escaping LoadDeviceID
	) {
		self.snapshotOfProfileForExport = snapshotOfProfileForExport
		self.loadProfileBackups = loadProfileBackups
		self.importProfileSnapshot = importProfileSnapshot
		self.didExportProfileSnapshot = didExportProfileSnapshot
		self.loadDeviceID = loadDeviceID
	}
}

extension BackupsClient {
	public typealias SnapshotOfProfileForExport = @Sendable () async throws -> Profile
	public typealias LoadProfileBackups = @Sendable () async -> Profile.HeaderList?
	public typealias ImportProfileSnapshot = @Sendable (Profile, Set<FactorSourceIDFromHash>, Bool) async throws -> Void
	public typealias DidExportProfileSnapshot = @Sendable (Profile) throws -> Void
	public typealias LoadDeviceID = @Sendable () async -> UUID?
}

import ClientPrelude
import Profile

// MARK: - BackupsClient
public struct BackupsClient: Sendable {
	public var snapshotOfProfileForExport: SnapshotOfProfileForExport
	public var loadProfileBackups: LoadProfileBackups
	public var importProfileSnapshot: ImportProfileSnapshot
	public var importCloudProfile: ImportCloudProfile
	public var loadDeviceID: LoadDeviceID

	public init(
		snapshotOfProfileForExport: @escaping SnapshotOfProfileForExport,
		loadProfileBackups: @escaping LoadProfileBackups,
		importProfileSnapshot: @escaping ImportProfileSnapshot,
		importCloudProfile: @escaping ImportCloudProfile,
		loadDeviceID: @escaping LoadDeviceID
	) {
		self.snapshotOfProfileForExport = snapshotOfProfileForExport
		self.loadProfileBackups = loadProfileBackups
		self.importProfileSnapshot = importProfileSnapshot
		self.importCloudProfile = importCloudProfile
		self.loadDeviceID = loadDeviceID
	}
}

extension BackupsClient {
	public typealias SnapshotOfProfileForExport = @Sendable () async throws -> ProfileSnapshot
	public typealias LoadProfileBackups = @Sendable () async -> ProfileSnapshot.HeaderList?

	public typealias ImportProfileSnapshot = @Sendable (ProfileSnapshot, FactorSourceID) async throws -> Void
	public typealias ImportCloudProfile = @Sendable (ProfileSnapshot.Header, FactorSourceID) async throws -> Void

	public typealias LoadDeviceID = @Sendable () async -> UUID?
}

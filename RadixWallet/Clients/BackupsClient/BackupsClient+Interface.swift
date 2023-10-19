// MARK: - BackupsClient
public struct BackupsClient: Sendable {
	public var snapshotOfProfileForExport: SnapshotOfProfileForExport
	public var loadProfileBackups: LoadProfileBackups
	public var lookupProfileSnapshotByHeader: LookupProfileSnapshotByHeader
	public var importProfileSnapshot: ImportProfileSnapshot
	public var importCloudProfile: ImportCloudProfile
	public var loadDeviceID: LoadDeviceID

	public init(
		snapshotOfProfileForExport: @escaping SnapshotOfProfileForExport,
		loadProfileBackups: @escaping LoadProfileBackups,
		lookupProfileSnapshotByHeader: @escaping LookupProfileSnapshotByHeader,
		importProfileSnapshot: @escaping ImportProfileSnapshot,
		importCloudProfile: @escaping ImportCloudProfile,
		loadDeviceID: @escaping LoadDeviceID
	) {
		self.snapshotOfProfileForExport = snapshotOfProfileForExport
		self.loadProfileBackups = loadProfileBackups
		self.lookupProfileSnapshotByHeader = lookupProfileSnapshotByHeader
		self.importProfileSnapshot = importProfileSnapshot
		self.importCloudProfile = importCloudProfile
		self.loadDeviceID = loadDeviceID
	}
}

extension BackupsClient {
	public typealias SnapshotOfProfileForExport = @Sendable () async throws -> ProfileSnapshot
	public typealias LoadProfileBackups = @Sendable () async -> ProfileSnapshot.HeaderList?

	public typealias ImportProfileSnapshot = @Sendable (ProfileSnapshot, Set<FactorSourceID.FromHash>) async throws -> Void
	public typealias ImportCloudProfile = @Sendable (ProfileSnapshot.Header, Set<FactorSourceID.FromHash>) async throws -> Void
	public typealias LookupProfileSnapshotByHeader = @Sendable (ProfileSnapshot.Header) async throws -> ProfileSnapshot?

	public typealias LoadDeviceID = @Sendable () async -> UUID?
}

extension BackupsClient {
	public func importSnapshot(
		_ snapshot: ProfileSnapshot,
		fromCloud: Bool
	) async throws {
		let factorSourceIDs: Set<FactorSourceID.FromHash> = .init(
			snapshot.factorSources.compactMap { $0.extract(DeviceFactorSource.self) }.map(\.id)
		)
		if fromCloud {
			try await importCloudProfile(snapshot.header, factorSourceIDs)
		} else {
			try await importProfileSnapshot(snapshot, factorSourceIDs)
		}
	}
}

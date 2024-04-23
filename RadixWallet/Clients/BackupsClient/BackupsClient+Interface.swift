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
	public typealias SnapshotOfProfileForExport = @Sendable () async throws -> Profile
	public typealias LoadProfileBackups = @Sendable () async -> Profile.HeaderList?

	public typealias ImportProfileSnapshot = @Sendable (Profile, Set<FactorSourceIDFromHash>) async throws -> Void
	public typealias ImportCloudProfile = @Sendable (Profile.Header, Set<FactorSourceIDFromHash>) async throws -> Void
	public typealias LookupProfileSnapshotByHeader = @Sendable (Profile.Header) async throws -> Profile?

	public typealias LoadDeviceID = @Sendable () async -> UUID?
}

extension BackupsClient {
	public func importSnapshot(
		_ snapshot: Profile,
		fromCloud: Bool
	) async throws {
		let factorSourceIDs: Set<FactorSourceIDFromHash> = .init(
			snapshot.factorSources.compactMap { $0.extract(DeviceFactorSource.self) }.map(\.id)
		)
		if fromCloud {
			try await importCloudProfile(snapshot.header, factorSourceIDs)
		} else {
			try await importProfileSnapshot(snapshot, factorSourceIDs)
		}
	}
}

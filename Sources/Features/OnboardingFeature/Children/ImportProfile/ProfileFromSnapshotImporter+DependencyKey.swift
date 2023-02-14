import FeaturePrelude
import ProfileClient

public typealias ProfileFromSnapshotImporter = @Sendable (ProfileSnapshot) throws -> Profile

// MARK: - ProfileFromSnapshotImporterKey
private enum ProfileFromSnapshotImporterKey: DependencyKey {
	typealias Value = ProfileFromSnapshotImporter
	static let liveValue = { @Sendable in try Profile(snapshot: $0) }
}

extension DependencyValues {
	public var profileFromSnapshotImporter: ProfileFromSnapshotImporter {
		get { self[ProfileFromSnapshotImporterKey.self] }
		set { self[ProfileFromSnapshotImporterKey.self] = newValue }
	}
}

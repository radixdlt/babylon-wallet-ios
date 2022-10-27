import Dependencies
import Foundation
import Profile

public typealias ProfileFromSnapshotImporter = (ProfileSnapshot) throws -> Profile

// MARK: - ProfileFromSnapshotImporterKey
private enum ProfileFromSnapshotImporterKey: DependencyKey {
	typealias Value = ProfileFromSnapshotImporter
	static let liveValue = { try Profile(snapshot: $0) }
}

public extension DependencyValues {
	var profileFromSnapshotImporter: ProfileFromSnapshotImporter {
		get { self[ProfileFromSnapshotImporterKey.self] }
		set { self[ProfileFromSnapshotImporterKey.self] = newValue }
	}
}

import ComposableArchitecture
import Foundation
import Profile

// MARK: - ImportProfile.Action
public extension ImportProfile {
	enum Action: Equatable {
		case coordinate(Coordinate)
		case `internal`(Internal)
	}
}

public extension ImportProfile {
	enum Internal: Equatable {
		case goBack
		case importProfileFile
		case dismissFileimporter
		case importProfileFileResult(TaskResult<URL>)
		case importProfileDataFromFileAt(URL)
		case importProfileDataResult(TaskResult<Data>)
		case importProfileSnapshotFromDataResult(TaskResult<ProfileSnapshot>)
		case saveProfileSnapshot(ProfileSnapshot)
		case saveProfileSnapshotResult(TaskResult<ProfileSnapshot>)
	}

	enum Coordinate: Equatable {
		case goBack
		case importedProfileSnapshot(ProfileSnapshot)
		case failedToImportProfileSnapshot(reason: String)
	}
}

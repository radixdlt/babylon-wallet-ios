import ComposableArchitecture
import Foundation
import KeychainClient
import Profile
import ProfileClient // FIXME: only need `KeychainClientKey`, which lives here... how to handle this best since KeychainClient is defined in Profile repo but we want to create our live value in any of our Packages (here ProfileClient..)?

// MARK: - ImportProfile
public struct ImportProfile: ReducerProtocol {
	@Dependency(\.keychainClient) var keychainClient
	@Dependency(\.jsonDecoder) var jsonDecoder
	public init() {}
}

// MARK: ReducerProtocol Conformance
public extension ImportProfile {
	func reduce(into state: inout State, action: Action) -> Effect<Action, Never> {
		switch action {
		case .internal(.goBack):
			return .run { send in
				await send(.coordinate(.goBack))
			}

		case .internal(.dismissFileimporter):
			state.isDisplayingFileImporter = false
			return .none

		case .internal(.importProfileFile):
			state.isDisplayingFileImporter = true
			return .none

		case let .internal(.importProfileFileResult(.failure(error))):
			return .run { send in
				await send(.coordinate(.failedToImportProfileSnapshot(reason: "Failed to import file, error: \(String(describing: error))")))
			}

		case let .internal(.importProfileFileResult(.success(profileURL))):
			return .run { send in
				await send(.internal(.importProfileDataFromFileAt(profileURL)))
			}

		case let .internal(.importProfileDataFromFileAt(profileFileURL)):
			return .run { send in
				await send(.internal(.importProfileDataResult(TaskResult { try Data(contentsOf: profileFileURL, options: .uncached) })))
			}

		case let .internal(.importProfileDataResult(.success(profileData))):
			return .run { [jsonDecoder] send in
				await send(.internal(.importProfileSnapshotFromDataResult(TaskResult {
					try jsonDecoder.decode(ProfileSnapshot.self, from: profileData)
				})))
			}

		case let .internal(.importProfileDataResult(.failure(error))):
			return .run { send in
				await send(.coordinate(.failedToImportProfileSnapshot(reason: "Failed to import ProfileSnapshot data, error: \(String(describing: error))")))
			}

		case let .internal(.importProfileSnapshotFromDataResult(.success(profileSnapshot))):
			return .run { send in
				await send(.internal(.saveProfileSnapshot(profileSnapshot)))
			}

		case let .internal(.importProfileSnapshotFromDataResult(.failure(error))):
			return .run { send in
				await send(.coordinate(.failedToImportProfileSnapshot(reason: "Failed to import ProfileSnapshot from data, error: \(String(describing: error))")))
			}

		case let .internal(.saveProfileSnapshot(profileSnapshotToSave)):
			return .run { [keychainClient] send in
				await send(.internal(.saveProfileSnapshotResult(
					TaskResult {
						try keychainClient.saveProfileSnapshot(profileSnapshot: profileSnapshotToSave)
					}.map { profileSnapshotToSave }
				)))
			}

		case let .internal(.saveProfileSnapshotResult(.success(savedProfileSnapshot))):
			return .run { send in
				await send(.coordinate(.importedProfileSnapshot(savedProfileSnapshot)))
			}

		case let .internal(.saveProfileSnapshotResult(.failure(error))):
			return .run { send in
				await send(.coordinate(.failedToImportProfileSnapshot(reason: "Failed to save ProfileSnapshot, error: \(String(describing: error))")))
			}

		case .coordinate: return .none
		}
	}
}

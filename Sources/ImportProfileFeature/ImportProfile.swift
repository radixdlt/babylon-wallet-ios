import ComposableArchitecture
import Foundation
import KeychainClient
import Profile
import ProfileClient // FIXME: only need `KeychainClientKey`, which lives here... how to handle this best since KeychainClient is defined in Profile repo but we want to create our live value in any of our Packages (here ProfileClient..)?
import SwiftUI

// MARK: - JSONDecoderKey
private enum JSONDecoderKey: DependencyKey {
	typealias Value = JSONDecoder
	static let liveValue = {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		return decoder
	}()
}

// MARK: - JSONDecoder + Sendable
@available(iOS 15, macOS 12, *) extension JSONDecoder: @unchecked Sendable {}

public extension DependencyValues {
	var jsonDecoder: JSONDecoder {
		get { self[JSONDecoderKey.self] }
		set { self[JSONDecoderKey.self] = newValue }
	}
}

// MARK: - ImportProfile
public struct ImportProfile: ReducerProtocol {
	@Dependency(\.keychainClient) var keychainClient
	@Dependency(\.jsonDecoder) var jsonDecoder
	public init() {}
}

// MARK: ImportProfile.State
public extension ImportProfile {
	struct State: Equatable {
		public var isDisplayingFileImporter = false

		public init(
			isDisplayingFileImporter: Bool = false
		) {
			self.isDisplayingFileImporter = isDisplayingFileImporter
		}
	}
}

// MARK: ImportProfile.Action
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

// MARK: ImportProfile.View
public extension ImportProfile {
	struct View: SwiftUI.View {
		let store: StoreOf<ImportProfile>
		public init(store: StoreOf<ImportProfile>) {
			self.store = store
		}
	}
}

public extension ImportProfile.View {
	var body: some View {
		WithViewStore(
			store,
			observe: { $0 }
		) { viewStore in
			VStack {
				HStack {
					Button(
						action: {
							viewStore.send(.internal(.goBack))
						}, label: {
							Image("arrow-back")
						}
					)
					Spacer()
					Text("Import profile")
					Spacer()
					EmptyView()
				}
				Spacer()

				Button("Import Profile") {
					viewStore.send(.internal(.importProfileFile))
				}
				.buttonStyle(.borderedProminent)
				Spacer()
			}
			.fileImporter(
				isPresented: viewStore.binding(
					get: \.isDisplayingFileImporter,
					send: ImportProfile.Action.internal(.dismissFileimporter)
				),
				allowedContentTypes: [.profile],
				onCompletion: {
					let taskResult: TaskResult<URL> = TaskResult($0)
					viewStore.send(.internal(.importProfileFileResult(taskResult)))
				}
			)
		}
	}
}

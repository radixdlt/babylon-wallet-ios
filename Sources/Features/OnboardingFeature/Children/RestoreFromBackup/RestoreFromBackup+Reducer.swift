import FeaturePrelude
import OnboardingClient

public struct RestoreFromBackup: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public typealias BackupProfileHeaders = NonEmpty<IdentifiedArrayOf<ProfileSnapshot.Header>>
		var backupProfileHeaders: BackupProfileHeaders?
		var selectedProfileHeader: ProfileSnapshot.Header?

		public var isDisplayingFileImporter = false

		public init(backupProfileHeaders: BackupProfileHeaders? = nil) {
			self.backupProfileHeaders = backupProfileHeaders
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case tappedImportProfile
		case tappedUseCloudBackup
		case selectedProfileHeader(ProfileSnapshot.Header?)
		case dismissFileImporter
		case profileImported(Result<URL, NSError>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed
	}

	public enum InternalAction: Sendable, Equatable {
		case loadBackupProfileHeadersResult(State.BackupProfileHeaders?)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.dataReader) var dataReader
	@Dependency(\.jsonDecoder) var jsonDecoder
	@Dependency(\.onboardingClient) var onboardingClient

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { send in
				await send(.internal(.loadBackupProfileHeadersResult(
					onboardingClient.loadProfileBackups()
				)))
			}

		case .tappedImportProfile:
			state.isDisplayingFileImporter = true
			return .none

		case let .selectedProfileHeader(header):
			state.selectedProfileHeader = header
			return .none

		case .tappedUseCloudBackup:
			guard let selectedProfileHeader = state.selectedProfileHeader else {
				return .none
			}

			return .run { send in
				try await onboardingClient.importCloudProfile(selectedProfileHeader)
				await send(.delegate(.completed))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case .dismissFileImporter:
			state.isDisplayingFileImporter = false
			return .none
		case let .profileImported(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .profileImported(.success(profileURL)):
			return .run { send in
				let data = try dataReader.contentsOf(profileURL, options: .uncached)
				let snapshot = try jsonDecoder().decode(ProfileSnapshot.self, from: data)
				try await onboardingClient.importProfileSnapshot(snapshot)
				await send(.delegate(.completed))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadBackupProfileHeadersResult(profileHeaders):
			state.backupProfileHeaders = profileHeaders
			return .none
		}
	}
}

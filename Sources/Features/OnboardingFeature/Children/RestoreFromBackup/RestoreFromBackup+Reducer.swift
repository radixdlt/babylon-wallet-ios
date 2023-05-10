import FeaturePrelude
import OnboardingClient

public struct RestoreFromBackup: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public typealias BackupProfiles = NonEmpty<IdentifiedArrayOf<Profile>>
		var backupProfiles: BackupProfiles?
		var selectedProfile: Profile?

		public var isDisplayingFileImporter = false

		public init(backupProfiles: BackupProfiles? = nil) {
			self.backupProfiles = backupProfiles
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case tappedImportProfile
		case tappedUseICloudBackup
		case selectedProfile(Profile?)
		case dismissFileImporter
		case profileImported(Result<URL, NSError>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed
	}

	public enum InternalAction: Sendable, Equatable {
		case loadBackupProfilesResult(State.BackupProfiles?)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.dataReader) var dataReader
	@Dependency(\.jsonDecoder) var jsonDecoder
	@Dependency(\.onboardingClient) var onboardingClient

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { send in
				await send(.internal(.loadBackupProfilesResult(
					onboardingClient.loadProfileBackups()
				)))
			}

		case .tappedImportProfile:
			state.isDisplayingFileImporter = true
			return .none

		case let .selectedProfile(profile):
			state.selectedProfile = profile
			return .none

		case .tappedUseICloudBackup:
			guard let selectedProfile = state.selectedProfile else {
				return .none
			}

			return .run { send in
				try await onboardingClient.importICloudProfile(selectedProfile.header)
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
		case let .loadBackupProfilesResult(profiles):
			state.backupProfiles = profiles
			return .none
		}
	}
}

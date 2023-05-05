import FeaturePrelude
import OnboardingClient

public struct RestoreFromBackup: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public typealias BackupProfiles = NonEmpty<IdentifiedArrayOf<Profile>>
		var backupProfiles: BackupProfiles?
		var selectedProfile: Profile?

		public init(backupProfiles: BackupProfiles? = nil) {
			self.backupProfiles = backupProfiles
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case selectedProfile(Profile)
		case dismissedSelectedProfile
		case importProfile(Profile)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed
	}

	public enum InternalAction: Sendable, Equatable {
		case loadBackupProfilesResult(State.BackupProfiles?)
		case didImportProfile
	}

	@Dependency(\.onboardingClient) var onboardingClient

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { send in
				await send(.internal(.loadBackupProfilesResult(
					await onboardingClient.loadProfileBackups()
				)))
			}
		case let .selectedProfile(profile):
			state.selectedProfile = profile
			return .none
		case let .importProfile(profile):
			return .run { send in
				try await onboardingClient.importProfileSnapshot(profile.snapshot())
				await send(.internal(.didImportProfile))
			}
		case .dismissedSelectedProfile:
			state.selectedProfile = nil
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadBackupProfilesResult(profiles):
			state.backupProfiles = profiles
			return .none
		case .didImportProfile:
			return .send(.delegate(.completed))
		}
	}
}

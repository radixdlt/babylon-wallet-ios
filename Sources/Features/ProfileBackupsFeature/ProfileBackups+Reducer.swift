import AppPreferencesClient
import BackupsClient
import FeaturePrelude
import ImportMnemonicFeature

// MARK: - ScanQR
public struct ProfileBackups: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var preferences: AppPreferences?
		public var backupProfileHeaders: ProfileSnapshot.HeaderList?
		public var selectedProfileHeader: ProfileSnapshot.Header?
		public var isDisplayingFileImporter: Bool
		public var thisDeviceID: UUID?

		var isCloudProfileSyncEnabled: Bool {
			preferences?.security.isCloudProfileSyncEnabled == true
		}

		@PresentationState
		public var alert: Alerts.State?

		/// Temporary flag to drive the UI based on the location.
		/// In the future we most probably would want to allow users to import/select a backup also from the settings.
		public var shownInSettings: Bool

		public init(
			shownInSettings: Bool,
			backupProfileHeaders: ProfileSnapshot.HeaderList? = nil,
			selectedProfileHeader: ProfileSnapshot.Header? = nil,
			isDisplayingFileImporter: Bool = false,
			thisDeviceID: UUID? = nil
		) {
			self.shownInSettings = shownInSettings
			self.backupProfileHeaders = backupProfileHeaders
			self.selectedProfileHeader = selectedProfileHeader
			self.isDisplayingFileImporter = isDisplayingFileImporter
			self.thisDeviceID = thisDeviceID
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case cloudProfileSyncToggled(Bool)
		case alert(PresentationAction<Alerts.Action>)
		case selectedProfileHeader(ProfileSnapshot.Header?)
		case tappedImportProfile
		case dismissFileImporter
		case profileImportResult(Result<URL, NSError>)
		case tappedUseCloudBackup
	}

	public struct Alerts: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case confirmCloudSyncDisable(AlertState<Action.ConfirmCloudSyncDisable>)
		}

		public enum Action: Sendable, Equatable {
			case confirmCloudSyncDisable(ConfirmCloudSyncDisable)

			public enum ConfirmCloudSyncDisable: Sendable, Hashable {
				case confirm
			}
		}

		public var body: some ReducerProtocolOf<Self> {
			EmptyReducer()
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case loadBackupProfileHeadersResult(ProfileSnapshot.HeaderList?)
		case loadThisDeviceIDResult(UUID?)
		case loadPreferences(AppPreferences)
	}

	public enum DelegateAction: Sendable, Equatable {
		case profileImported
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.dataReader) var dataReader
	@Dependency(\.jsonDecoder) var jsonDecoder
	@Dependency(\.backupsClient) var backupsClient
	@Dependency(\.appPreferencesClient) var appPreferencesClient

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .cloudProfileSyncToggled(isEnabled):
			if !isEnabled {
				state.alert = .confirmCloudSyncDisable(.init(
					title: {
						TextState("Disabling iCloud sync will delete the iCloud backup data, are you sure you want to disable iCloud sync?")
					},
					actions: {
						ButtonState(role: .destructive, action: .confirm) {
							TextState("Confirm")
						}
					}
				))
				return .none
			} else {
				return updateCloudSync(state: &state, isEnabled: true)
			}

		case .alert(.presented(.confirmCloudSyncDisable(.confirm))):
			state.alert = nil
			return updateCloudSync(state: &state, isEnabled: false)

		case .alert(.dismiss):
			return .none

		case .task:
			return .run { send in
				await send(.internal(.loadThisDeviceIDResult(
					backupsClient.loadDeviceID()
				)))

				await send(.internal(.loadBackupProfileHeadersResult(
					backupsClient.loadProfileBackups()
				)))

				await send(.internal(.loadPreferences(
					appPreferencesClient.getPreferences()
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
				try await backupsClient.importCloudProfile(selectedProfileHeader)
				await send(.delegate(.profileImported))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case .dismissFileImporter:
			state.isDisplayingFileImporter = false
			return .none

		case let .profileImportResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .profileImportResult(.success(profileURL)):
			return .run { send in
				let data = try dataReader.contentsOf(profileURL, options: .uncached)
				let snapshot = try jsonDecoder().decode(ProfileSnapshot.self, from: data)
				try await backupsClient.importProfileSnapshot(snapshot)
				await send(.delegate(.profileImported))
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
		case let .loadThisDeviceIDResult(identifier):
			state.thisDeviceID = identifier
			return .none
		case let .loadPreferences(preferences):
			state.preferences = preferences
			return .none
		}
	}

	private func updateCloudSync(state: inout State, isEnabled: Bool) -> EffectTask<Action> {
		state.preferences?.security.isCloudProfileSyncEnabled = isEnabled
		return .fireAndForget {
			try await appPreferencesClient.setIsCloudProfileSyncEnabled(false)
		}
	}
}

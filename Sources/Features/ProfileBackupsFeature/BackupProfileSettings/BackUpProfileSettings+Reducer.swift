import AppPreferencesClient
import BackupsClient
import CacheClient
import Cryptography
import FeaturePrelude
import ImportMnemonicFeature
import OverlayWindowClient
import RadixConnectClient

// MARK: - BackUpProfileSettings
public struct BackUpProfileSettings: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var preferences: AppPreferences?
		public var backupProfileHeaders: ProfileSnapshot.HeaderList?
		public var selectedProfileHeader: ProfileSnapshot.Header?
		public var isDisplayingFileExporter: Bool {
			profileFilePotentiallyEncrypted != nil
		}

		public var thisDeviceID: UUID?

		var isCloudProfileSyncEnabled: Bool {
			preferences?.security.isCloudProfileSyncEnabled == true
		}

		@PresentationState
		public var destination: Destinations.State?

		public var profileFilePotentiallyEncrypted: ExportableProfileFile?

		public init(
			backupProfileHeaders: ProfileSnapshot.HeaderList? = nil,
			selectedProfileHeader: ProfileSnapshot.Header? = nil,
			thisDeviceID: UUID? = nil
		) {
			self.backupProfileHeaders = backupProfileHeaders
			self.selectedProfileHeader = selectedProfileHeader
			self.thisDeviceID = thisDeviceID
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case cloudProfileSyncToggled(Bool)
		case exportProfileButtonTapped
		case dismissFileExporter
		case profileExportResult(Result<URL, NSError>)

		case deleteProfileAndFactorSourcesButtonTapped
	}

	public struct Destinations: Sendable, ReducerProtocol {
		static let confirmCloudSyncDisableAlert: Self.State = .confirmCloudSyncDisable(.init(
			title: {
				// FIXME: Strings
				TextState("Disabling iCloud sync will delete the iCloud backup data(wallet data will still be kept on this iPhone), are you sure you want to disable iCloud sync?")
			},
			actions: {
				ButtonState(role: .destructive, action: .confirm) {
					// FIXME: Strings
					TextState("Confirm")
				}
			}
		))

		static let optionallyEncryptProfileBeforeExportingAlert: Self.State = .optionallyEncryptProfileBeforeExporting(.init(
			title: {
				// FIXME: Strings
				TextState("Encrypt this backup with a password?")
			},
			actions: {
				ButtonState(role: .destructive, action: .encrypt) {
					// FIXME: Strings
					TextState("Yes")
				}
				ButtonState(role: .destructive, action: .doNotEncrypt) {
					// FIXME: Strings
					TextState("No")
				}
			}
		))

		public enum State: Sendable, Hashable {
			case confirmCloudSyncDisable(AlertState<Action.ConfirmCloudSyncDisable>)
			case optionallyEncryptProfileBeforeExporting(AlertState<Action.SelectEncryptOrNot>)
			case deleteProfileConfirmationDialog(ConfirmationDialogState<Action.DeleteProfileConfirmationDialogAction>)

			case inputEncryptionPassword(EncryptOrDecryptProfile.State)
		}

		public enum Action: Sendable, Equatable {
			case confirmCloudSyncDisable(ConfirmCloudSyncDisable)
			case optionallyEncryptProfileBeforeExporting(SelectEncryptOrNot)

			case inputEncryptionPassword(EncryptOrDecryptProfile.Action)

			public enum ConfirmCloudSyncDisable: Sendable, Hashable {
				case confirm
			}

			public enum SelectEncryptOrNot: Sendable, Hashable {
				case encrypt
				case doNotEncrypt
			}

			case deleteProfileConfirmationDialog(DeleteProfileConfirmationDialogAction)

			public enum DeleteProfileConfirmationDialogAction: Sendable, Hashable {
				case deleteProfile
				case deleteProfileLocalKeepInICloudIfPresent
				case cancel
			}
		}

		public var body: some ReducerProtocol<State, Action> {
			Scope(state: /State.confirmCloudSyncDisable, action: /Action.confirmCloudSyncDisable) {
				EmptyReducer()
			}
			Scope(state: /State.optionallyEncryptProfileBeforeExporting, action: /Action.optionallyEncryptProfileBeforeExporting) {
				EmptyReducer()
			}
			Scope(state: /State.inputEncryptionPassword, action: /Action.inputEncryptionPassword) {
				EncryptOrDecryptProfile()
			}
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedProfileSnapshotToExportAsPlaintext(ProfileSnapshot)
		case loadPreferences(AppPreferences)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case deleteProfileAndFactorSources(keepInICloudIfPresent: Bool)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.cacheClient) var cacheClient
	@Dependency(\.backupsClient) var backupsClient
	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.radixConnectClient) var radixConnectClient
	@Dependency(\.overlayWindowClient) var overlayWindowClient

	public init() {}

	public var body: some ReducerProtocolOf<BackUpProfileSettings> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. /ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .deleteProfileAndFactorSourcesButtonTapped:
			state.destination = .deleteProfileConfirmationDialog(.deleteProfileConfirmationDialog)
			return .none

		case let .cloudProfileSyncToggled(isEnabled):
			if !isEnabled {
				state.destination = Destinations.confirmCloudSyncDisableAlert
				return .none
			} else {
				return updateCloudSync(state: &state, isEnabled: true)
			}

		case .exportProfileButtonTapped:
			state.destination = Destinations.optionallyEncryptProfileBeforeExportingAlert
			return .none

		case .task:
			return .run { send in
				await send(.internal(.loadPreferences(
					appPreferencesClient.getPreferences()
				)))
			}

		case .dismissFileExporter:
			state.profileFilePotentiallyEncrypted = nil
			return .none

		case let .profileExportResult(.success(exportedProfileURL)):
			let didEncryptIt = exportedProfileURL.absoluteString.contains(.profileFileEncryptedPart)
			overlayWindowClient.scheduleHUD(.exportedProfile(encrypted: didEncryptIt))
			loggerGlobal.notice("Profile successfully exported to: \(exportedProfileURL)")
			return .none

		case let .profileExportResult(.failure(error)):
			loggerGlobal.error("Failed to export profile, error: \(error)")
			errorQueue.schedule(error)
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadPreferences(preferences):
			state.preferences = preferences
			return .none

		case let .loadedProfileSnapshotToExportAsPlaintext(snapshot):
			return showFileExporter(with: .plaintext(snapshot), &state)
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(.deleteProfileConfirmationDialog(confirmationAction))):
			switch confirmationAction {
			case .deleteProfile:
				return deleteProfile(keepInICloudIfPresent: false)

			case .deleteProfileLocalKeepInICloudIfPresent:
				return deleteProfile(keepInICloudIfPresent: true)

			case .cancel:
				return .none
			}

		case .destination(.presented(.optionallyEncryptProfileBeforeExporting(.doNotEncrypt))):
			return exportProfile(encrypt: false, state: &state)

		case .destination(.presented(.optionallyEncryptProfileBeforeExporting(.encrypt))):
			return exportProfile(encrypt: true, state: &state)

		case .destination(.presented(.confirmCloudSyncDisable(.confirm))):
			state.destination = nil
			return updateCloudSync(state: &state, isEnabled: false)

		case .destination(.presented(.inputEncryptionPassword(.delegate(.dismiss)))):
			state.destination = nil
			return .none

		case .destination(.presented(.inputEncryptionPassword(.delegate(.successfullyDecrypted)))):
			preconditionFailure("What? Decrypted? Expected to only have ENCRYPTED. Incorrect implementation somewhere...")
			return .none

		case let .destination(.presented(.inputEncryptionPassword(.delegate(.successfullyEncrypted(_, encrypted: encrypted))))):
			state.destination = nil
			return showFileExporter(with: .encrypted(encrypted), &state)

		case .destination(.dismiss):
			state.destination = nil
			return .none

		default:
			return .none
		}
	}

	private func showFileExporter(with file: ExportableProfileFile, _ state: inout State) -> EffectTask<Action> {
		// This will trigger `fileExporter` to be shown
		state.profileFilePotentiallyEncrypted = file
		return .none
	}

	private func exportProfile(encrypt: Bool, state: inout State) -> EffectTask<Action> {
		if encrypt {
			state.destination = .inputEncryptionPassword(.init(mode: .loadThenEncrypt()))
			return .none
		} else {
			return .run { send in
				do {
					let snapshot = try await backupsClient.snapshotOfProfileForExport()
					await send(.internal(.loadedProfileSnapshotToExportAsPlaintext(snapshot)))
				} catch {
					loggerGlobal.error("Failed to encrypt profile snapshot, error: \(error)")
					errorQueue.schedule(error)
				}
			}
		}
	}

	private func updateCloudSync(state: inout State, isEnabled: Bool) -> EffectTask<Action> {
		state.preferences?.security.isCloudProfileSyncEnabled = isEnabled
		return .fireAndForget {
			try await appPreferencesClient.setIsCloudProfileSyncEnabled(isEnabled)
		}
	}

	private func deleteProfile(keepInICloudIfPresent: Bool) -> EffectTask<Action> {
		.task {
			cacheClient.removeAll()
			await radixConnectClient.disconnectAndRemoveAll()
			return .delegate(.deleteProfileAndFactorSources(keepInICloudIfPresent: keepInICloudIfPresent))
		}
	}
}

// MARK: - LackedPermissionToAccessSecurityScopedResource
struct LackedPermissionToAccessSecurityScopedResource: Error {}

extension ConfirmationDialogState<BackUpProfileSettings.Destinations.Action.DeleteProfileConfirmationDialogAction> {
	static let deleteProfileConfirmationDialog = ConfirmationDialogState {
		TextState(L10n.AppSettings.ResetWalletDialog.title)
	} actions: {
		ButtonState(role: .destructive, action: .deleteProfileLocalKeepInICloudIfPresent) {
			TextState(L10n.AppSettings.ResetWalletDialog.resetButtonTitle)
		}
		ButtonState(role: .destructive, action: .deleteProfile) {
			TextState(L10n.AppSettings.ResetWalletDialog.resetAndDeleteBackupButtonTitle)
		}
		ButtonState(role: .cancel, action: .cancel) {
			TextState(L10n.Common.cancel)
		}
	} message: {
		TextState(L10n.AppSettings.ResetWalletDialog.message)
	}
}

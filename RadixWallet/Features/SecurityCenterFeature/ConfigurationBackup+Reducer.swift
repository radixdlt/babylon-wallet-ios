import CloudKit
import ComposableArchitecture

// MARK: - ConfigurationBackup
public struct ConfigurationBackup: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var iCloudAccountStatus: CKAccountStatus? = nil
		public var automatedBackupsEnabled: Bool = true
		public var lastBackup: Date? = nil
		public var problems: [SecurityProblem]

		@PresentationState
		public var destination: Destination.State? = nil

		/// An exportable Profile file, either encrypted or plaintext. Setting this will trigger showing a file exporter
		public var profileFile: ExportableProfileFile?

		public init(problems: [SecurityProblem]) {
			self.problems = problems
		}

		public var outdatedBackupPresent: Bool {
			!automatedBackupsEnabled && lastBackup != nil
		}

		public var actionsRequired: [Item] {
			problems.isEmpty ? [] : Item.allCases
		}
	}

	public enum Item: Sendable, Hashable, CaseIterable {
		case accounts
		case personas
		case securityFactors
		case walletSettings
	}

	public enum ViewAction: Sendable, Equatable {
		case didAppear
		case automatedBackupsToggled(Bool)
		case exportTapped
		case deleteOutdatedTapped

		case showFileExporter(Bool)
		case profileExportResult(Result<URL, NSError>)
	}

	public enum InternalAction: Sendable, Equatable {
		case setCloudBackupEnabled(Bool)
		case setICloudAccountStatus(CKAccountStatus)
		case setLastBackedUp(Date?)
		case didDeleteOutdatedBackup(Profile.ID)

		case exportProfileSnapshot(ProfileSnapshot)
	}

	public struct Destination: DestinationReducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case encryptionPassword(EncryptOrDecryptProfile.State)
			case encryptProfileOrNot(AlertState<Action.EncryptProfileOrNot>)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case encryptionPassword(EncryptOrDecryptProfile.Action)
			case encryptProfileOrNot(EncryptProfileOrNot)

			public enum EncryptProfileOrNot: Sendable, Hashable {
				case encrypt
				case doNotEncrypt
			}
		}

		public var body: some Reducer<State, Action> {
			Scope(state: \.encryptionPassword, action: \.encryptionPassword) {
				EncryptOrDecryptProfile()
			}
		}
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.cloudBackupClient) var cloudBackupClient

	private func checkCloudBackupEnabledEffect() -> Effect<Action> {
		.run { send in
			let isEnabled = await ProfileStore.shared.profile.appPreferences.security.isCloudProfileSyncEnabled
			await send(.internal(.setCloudBackupEnabled(isEnabled)))
		}
	}

	private func checkCloudAccountStatusEffect() -> Effect<Action> {
		.run { send in
			do {
				let status = try await cloudBackupClient.checkAccountStatus()
				await send(.internal(.setICloudAccountStatus(status)))
			} catch {
				loggerGlobal.error("Failed to get iCloud account status: \(error)")
			}
		}
	}

	private func updateCloudBackupsSettingEffect(isEnabled: Bool) -> Effect<Action> {
		.run { send in
			do {
				try await appPreferencesClient.setIsCloudProfileSyncEnabled(isEnabled)
				await send(.internal(.setCloudBackupEnabled(isEnabled)))
				print("•• toggled cloud backups \(isEnabled)")
			} catch {
				loggerGlobal.error("Failed toggle cloud backups \(isEnabled ? "on" : "off"): \(error)")
			}
		}
	}

	private func updateLastBackupEffect() -> Effect<Action> {
		.run { send in
			let profile = await ProfileStore.shared.profile
			do {
				let lastBackedUp = try await cloudBackupClient.lastBackup(profile.id)
				await send(.internal(.setLastBackedUp(lastBackedUp)))
				print("•• got last backed up")
			} catch {
				loggerGlobal.error("Failed to fetch last backup for \(profile.id.uuidString): \(error)")
			}
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .didAppear:
			return updateLastBackupEffect()
				.merge(with: checkCloudAccountStatusEffect())

		case let .automatedBackupsToggled(isEnabled):
			print("•• automatedBackupsToggled")
			state.lastBackup = nil
			return updateCloudBackupsSettingEffect(isEnabled: isEnabled)
				.concatenate(with: updateLastBackupEffect())

		case .exportTapped:
			state.destination = .encryptProfileOrNot(.encryptProfileOrNotAlert)
			return .none

		case let .showFileExporter(show):
			if !show {
				state.profileFile = nil
			}
			return .none

		case .deleteOutdatedTapped:
			return .run { send in
				let profile = await ProfileStore.shared.profile
				do {
					try await cloudBackupClient.deleteProfile(profile.id)
					await send(.internal(.didDeleteOutdatedBackup(profile.id)))
					print("•• deleted outdate \(profile.id)")
				} catch {
					loggerGlobal.error("Failed to delete outdate backup \(profile.id.uuidString): \(error)")
				}
			}

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

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .encryptionPassword(.delegate(delegateAction)):
			switch delegateAction {
			case .dismiss:
				state.destination = nil
				print("•• encryptionPassword dismiss")
				return .none

			case .successfullyDecrypted:
				preconditionFailure("Incorrect implementation, should only ENcrypt")

			case let .successfullyEncrypted(_, encrypted: encryptedFile):
				print("•• successfullyEncrypted")
				state.destination = nil
				state.profileFile = .encrypted(encryptedFile)
				return .none
			}

		case .encryptionPassword:
			return .none

		case let .encryptProfileOrNot(encryptOrNot):
			switch encryptOrNot {
			case .encrypt:
				state.destination = .encryptionPassword(.init(mode: .loadThenEncrypt()))
				return .none

			case .doNotEncrypt:
				return .run { send in
					let snapshot = await ProfileStore.shared.profile.snapshot()
					await send(.internal(.exportProfileSnapshot(snapshot)))
				}
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setLastBackedUp(date):
			state.lastBackup = date
			return .none

		case let .didDeleteOutdatedBackup(id):
			state.lastBackup = nil
			print("•• didDeleteOutdatedBackup")
			// FIXME: GK - show alert? toast?
			return .none

		case let .setCloudBackupEnabled(isEnabled):
			print("•• set setCloudBackupEnabled: \(isEnabled)")
			state.automatedBackupsEnabled = isEnabled
			return .none

		case let .setICloudAccountStatus(status):
			print("•• set iCloudAccountStatus: \(status)")
			state.iCloudAccountStatus = status
			return .none

		case let .exportProfileSnapshot(snapshot):
			print("•• exportProfileSnapshot")

			state.profileFile = .plaintext(snapshot)
			return .none
		}
	}
}

extension AlertState<ConfigurationBackup.Destination.Action.EncryptProfileOrNot> {
	static let encryptProfileOrNotAlert: AlertState = .init(
		title: {
			TextState(L10n.ProfileBackup.ManualBackups.encryptBackupDialogTitle)
		},
		actions: {
			ButtonState(action: .encrypt) {
				TextState(L10n.ProfileBackup.ManualBackups.encryptBackupDialogConfirm)
			}
			ButtonState(action: .doNotEncrypt) {
				TextState(L10n.ProfileBackup.ManualBackups.encryptBackupDialogDeny)
			}
		}
	)
}

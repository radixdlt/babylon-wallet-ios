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

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.cloudBackupClient) var cloudBackupClient

	private func lastBackupEffect() -> Effect<Action> {
		.run { send in
			let profileID = await ProfileStore.shared.profile.id
			for try await lastBackup in cloudBackupClient.lastBackup(profileID) {
				guard !Task.isCancelled else { return }
				let modified = await ProfileStore.shared.profile.header.lastModified
				print("•• Backup changed for \(profileID.uuidString) \(lastBackup.profileModified == modified)")
				await send(.internal(.setLastBackedUp(lastBackup.profileModified)))
			}
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

	private func checkCloudBackupEnabledEffect() -> Effect<Action> {
		.run { send in
			let isEnabled = await ProfileStore.shared.profile.appPreferences.security.isCloudProfileSyncEnabled
			await send(.internal(.setCloudBackupEnabled(isEnabled)))
		}
	}

	private func updateCloudBackupsSettingEffect(isEnabled: Bool) -> Effect<Action> {
		.run { send in
			do {
				try await appPreferencesClient.setIsCloudProfileSyncEnabled(isEnabled)
				await send(.internal(.setCloudBackupEnabled(isEnabled)))
			} catch {
				loggerGlobal.error("Failed toggle cloud backups \(isEnabled ? "on" : "off"): \(error)")
			}
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .didAppear:
			return checkCloudAccountStatusEffect()
				.merge(with: checkCloudBackupEnabledEffect())

		case let .automatedBackupsToggled(isEnabled):
			state.lastBackup = nil
			return updateCloudBackupsSettingEffect(isEnabled: isEnabled)

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
					try await cloudBackupClient.deleteProfileInKeychain(profile.id)
					await send(.internal(.didDeleteOutdatedBackup(profile.id)))
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
		case let .encryptionPassword(.delegate(.successfullyEncrypted(_, encrypted: encryptedFile))):
			state.destination = nil
			state.profileFile = .encrypted(encryptedFile)
			return .none

		case .encryptionPassword:
			return .none

		case .encryptProfileOrNot(.encrypt):
			state.destination = .encryptionPassword(.init(mode: .loadThenEncrypt()))
			return .none

		case .encryptProfileOrNot(.doNotEncrypt):
			state.destination = nil
			return .run { send in
				let snapshot = await ProfileStore.shared.profile.snapshot()
				await send(.internal(.exportProfileSnapshot(snapshot)))
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

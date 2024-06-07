import CloudKit
import ComposableArchitecture

// MARK: - ConfigurationBackup
public struct ConfigurationBackup: Sendable, FeatureReducer {
	public struct Exportable: Sendable, Hashable {
		public let profile: Profile
		public let file: ExportableProfileFile
	}

	public struct State: Sendable, Hashable {
		public var iCloudAccountStatus: CKAccountStatus? = nil
		public var cloudBackupsEnabled: Bool = true
		public var lastManualBackup: Date? = nil
		public var lastCloudBackup: BackupStatus? = nil

		public var problems: [SecurityProblem] = []

		@PresentationState
		public var destination: Destination.State? = nil

		/// An exportable Profile file, either encrypted or plaintext. Setting this will trigger showing a file exporter
		public var exportable: Exportable? = nil

		public var outdatedBackupPresent: Bool {
			guard let lastCloudBackup, lastCloudBackup.result.succeeded else { return false }
			return !cloudBackupsEnabled && !lastCloudBackup.upToDate
		}

		public var actionsRequired: [Item] {
			guard let lastCloudBackup else { return [] }
			if lastCloudBackup.upToDate, !lastCloudBackup.result.failed {
				return []
			} else {
				return Item.allCases
			}
		}

		public var displayedLastBackup: Date? {
			guard let lastCloudBackup else { return nil }
			if lastCloudBackup.result.succeeded {
				return lastCloudBackup.upToDate ? nil : lastCloudBackup.result.backupDate
			} else {
				return lastCloudBackup.result.lastSuccess
			}
		}

		public init() {}
	}

	public enum Item: Sendable, Hashable, CaseIterable {
		case accounts
		case personas
		case securityFactors
		case walletSettings
	}

	public enum ViewAction: Sendable, Equatable {
		case didAppear
		case cloudBackupsToggled(Bool)
		case exportTapped
		case deleteOutdatedTapped
		case showFileExporter(Bool)
		case profileExportResult(Result<URL, NSError>, Profile?)
	}

	public enum InternalAction: Sendable, Equatable {
		case setCloudBackupEnabled(Bool)
		case setICloudAccountStatus(CKAccountStatus)
		case setProblems([SecurityProblem])
		case setLastManualBackup(Date?)
		case setLastCloudBackup(BackupStatus?)
		case exportProfile(Profile)
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
	@Dependency(\.transportProfileClient) var transportProfileClient
	@Dependency(\.securityCenterClient) var securityCenterClient
	@Dependency(\.userDefaults) var userDefaults

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .didAppear:
			return checkCloudAccountStatusEffect()
				.merge(with: checkCloudBackupEnabledEffect())
				.merge(with: problemsEffect())
				.merge(with: lastManualBackupEffect())
				.merge(with: lastCloudBackupEffect())

		case let .cloudBackupsToggled(isEnabled):
			return updateCloudBackupsSettingEffect(isEnabled: isEnabled)

		case .exportTapped:
			state.destination = .encryptProfileOrNot(.encryptProfileOrNotAlert)
			return .none

		case let .showFileExporter(show):
			if !show {
				state.exportable = nil
			}
			return .none

		case .deleteOutdatedTapped:
			return .run { _ in
				let profile = await ProfileStore.shared.profile
				do {
					try await cloudBackupClient.deleteProfileBackup(profile.id)
				} catch {
					loggerGlobal.error("Failed to delete outdate backup \(profile.id.uuidString): \(error)")
				}
			}

		case let .profileExportResult(.success(exportedProfileURL), profile):
			let didEncryptIt = exportedProfileURL.absoluteString.contains(.profileFileEncryptedPart)
			overlayWindowClient.scheduleHUD(.exportedProfile(encrypted: didEncryptIt))
			loggerGlobal.notice("Profile successfully exported to: \(exportedProfileURL)")
			if let profile {
				try? transportProfileClient.didExportProfile(profile)
			}
			return .none

		case let .profileExportResult(.failure(error), _):
			loggerGlobal.error("Failed to export profile, error: \(error)")
			errorQueue.schedule(error)
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .encryptionPassword(.delegate(.successfullyEncrypted(profile, encrypted: encryptedFile))):
			state.destination = nil
			state.exportable = .init(profile: profile, file: .encrypted(encryptedFile))
			return .none

		case .encryptionPassword:
			return .none

		case .encryptProfileOrNot(.encrypt):
			state.destination = .encryptionPassword(.init(mode: .loadThenEncrypt))
			return .none

		case .encryptProfileOrNot(.doNotEncrypt):
			state.destination = nil
			return .run { send in
				let profile = await ProfileStore.shared.profile
				await send(.internal(.exportProfile(profile)))
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setCloudBackupEnabled(isEnabled):
			state.cloudBackupsEnabled = isEnabled
			return .none

		case let .setICloudAccountStatus(status):
			state.iCloudAccountStatus = status
			return .none

		case let .setProblems(problems):
			state.problems = problems
			return .none

		case let .setLastCloudBackup(status):
			state.lastCloudBackup = status
			return .none

		case let .setLastManualBackup(date):
			state.lastManualBackup = date
			return .none

		case let .exportProfile(profile):
			state.exportable = .init(profile: profile, file: .plaintext(profile))
			return .none
		}
	}

	private func lastManualBackupEffect() -> Effect<Action> {
		.run { send in
			for try await lastBackup in await securityCenterClient.lastManualBackup() {
				guard !Task.isCancelled else { return }
				await send(.internal(.setLastManualBackup(lastBackup?.result.backupDate)))
			}
		}
	}

	private func lastCloudBackupEffect() -> Effect<Action> {
		.run { send in
			for try await lastBackup in await securityCenterClient.lastCloudBackup() {
				guard !Task.isCancelled else { return }
				await send(.internal(.setLastCloudBackup(lastBackup)))
			}
		}
	}

	private func problemsEffect() -> Effect<Action> {
		.run { send in
			for try await problems in await securityCenterClient.problems(.configurationBackup) {
				guard !Task.isCancelled else { return }
				await send(.internal(.setProblems(problems)))
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
				try await appPreferencesClient.setIsCloudBackupEnabled(isEnabled)
				await send(.internal(.setCloudBackupEnabled(isEnabled)))
			} catch {
				loggerGlobal.error("Failed toggle cloud backups \(isEnabled ? "on" : "off"): \(error)")
			}
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

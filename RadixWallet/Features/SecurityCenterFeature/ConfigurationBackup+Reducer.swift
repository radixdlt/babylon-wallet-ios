import CloudKit
import ComposableArchitecture

// MARK: - ConfigurationBackup
struct ConfigurationBackup: Sendable, FeatureReducer {
	struct Exportable: Sendable, Hashable {
		let profile: Profile
		let file: ExportableProfileFile
	}

	struct State: Sendable, Hashable {
		var cloudBackupsEnabled: Bool = true
		var lastManualBackup: Date? = nil
		var lastCloudBackup: BackupStatus? = nil

		var problems: [SecurityProblem] = []

		@PresentationState
		var destination: Destination.State? = nil

		/// An exportable Profile file, either encrypted or plaintext. Setting this will trigger showing a file exporter
		var exportable: Exportable? = nil

		var outdatedBackupPresent: Bool {
			guard let lastCloudBackup, lastCloudBackup.result.succeeded else { return false }
			return !cloudBackupsEnabled && !lastCloudBackup.isCurrent
		}

		var actionsRequired: [Item] {
			if let lastCloudBackup, lastCloudBackup.isCurrent, !lastCloudBackup.result.failed {
				[]
			} else {
				Item.allCases
			}
		}

		init() {}
	}

	enum Item: Sendable, Hashable, CaseIterable {
		case accounts
		case personas
		case securityFactors
		case walletSettings
	}

	enum ViewAction: Sendable, Equatable {
		case didAppear
		case cloudBackupsToggled(Bool)
		case exportTapped
		case deleteOutdatedTapped
		case showFileExporter(Bool)
		case profileExportResult(Result<URL, NSError>, Profile?)
	}

	enum InternalAction: Sendable, Equatable {
		case setCloudBackupEnabled(Bool)
		case setProblems([SecurityProblem])
		case setLastManualBackup(Date?)
		case setLastCloudBackup(BackupStatus?)
		case exportProfile(Profile)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case encryptionPassword(EncryptOrDecryptProfile.State)
			case encryptProfileOrNot(AlertState<Action.EncryptProfileOrNot>)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case encryptionPassword(EncryptOrDecryptProfile.Action)
			case encryptProfileOrNot(EncryptProfileOrNot)

			enum EncryptProfileOrNot: Sendable, Hashable {
				case encrypt
				case doNotEncrypt
			}
		}

		var body: some Reducer<State, Action> {
			Scope(state: \.encryptionPassword, action: \.encryptionPassword) {
				EncryptOrDecryptProfile()
			}
		}
	}

	var body: some ReducerOf<Self> {
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

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .didAppear:
			return problemsEffect()
				.merge(with: lastManualBackupEffect())
				.merge(with: lastCloudBackupEffect())
				.merge(with: isCloudBackupEnabledEffect())

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
				do {
					try await cloudBackupClient.deleteProfileBackup()
				} catch {
					loggerGlobal.error("Failed to delete outdated backup: \(error)")
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

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
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

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setCloudBackupEnabled(isEnabled):
			state.cloudBackupsEnabled = isEnabled
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
				await send(.internal(.setLastManualBackup(lastBackup?.result.date)))
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

	private func updateCloudBackupsSettingEffect(isEnabled: Bool) -> Effect<Action> {
		.run { _ in
			do {
				try await appPreferencesClient.setIsCloudBackupEnabled(isEnabled)
			} catch {
				loggerGlobal.error("Failed to toggle cloud backups \(isEnabled ? "on" : "off"): \(error)")
			}
		}
	}

	private func isCloudBackupEnabledEffect() -> Effect<Action> {
		.run { send in
			do {
				for try await isSyncEnabled in await cloudBackupClient.isCloudProfileSyncEnabled() {
					guard !Task.isCancelled else { return }
					await send(.internal(.setCloudBackupEnabled(isSyncEnabled)))
				}
			} catch {
				loggerGlobal.error("cloudBackupClient.isCloudProfileSyncEnabled failed: \(error)")
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

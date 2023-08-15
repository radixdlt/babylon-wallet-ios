import AppPreferencesClient
import BackupsClient
import Cryptography
import FeaturePrelude
import ImportMnemonicFeature
import UniformTypeIdentifiers

// MARK: - NoJSONDataFound
struct NoJSONDataFound: Error {}

// MARK: - EncryptedProfileSnapshot
public struct EncryptedProfileSnapshot: Sendable, Codable, Hashable {
	/// Encrypted JSON encoding of a `ProfileSnapshot`
	public let encryptedSnapshot: HexCodable
	public let encryptionScheme: EncryptionScheme
}

// MARK: - ExportableProfileFile
public enum ExportableProfileFile: FileDocument, Sendable, Hashable {
	case plaintext(ProfileSnapshot)
	case encrypted(EncryptedProfileSnapshot)
}

extension ExportableProfileFile {
	public static let readableContentTypes: [UTType] = [.profile]

	public init(configuration: ReadConfiguration) throws {
		guard let data = configuration.file.regularFileContents
		else {
			throw NoJSONDataFound()
		}
		try self.init(data: data)
	}

	public init(data: Data) throws {
		@Dependency(\.jsonDecoder) var jsonDecoder
		do {
			self = try .plaintext(jsonDecoder().decode(ProfileSnapshot.self, from: data))
		} catch {
			self = try .encrypted(jsonDecoder().decode(EncryptedProfileSnapshot.self, from: data))
		}
	}

	public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
		@Dependency(\.jsonEncoder) var jsonEncoder
		switch self {
		case let .plaintext(plaintext):
			let jsonData = try jsonEncoder().encode(plaintext)
			return FileWrapper(regularFileWithContents: jsonData)
		case let .encrypted(encryptedSnapshot):
			let jsonData = try jsonEncoder().encode(encryptedSnapshot)
			return FileWrapper(regularFileWithContents: jsonData)
		}
	}
}

// MARK: - ProfileBackups
public struct ProfileBackups: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Context: Sendable, Hashable {
			case onboarding
			case settings
		}

		public var preferences: AppPreferences?
		public var backupProfileHeaders: ProfileSnapshot.HeaderList?
		public var selectedProfileHeader: ProfileSnapshot.Header?
		public var isDisplayingFileImporter: Bool
		public var isDisplayingFileExporter: Bool
		public var thisDeviceID: UUID?
		public var context: Context

		public var importedEncryptedSnapshot: EncryptedProfileSnapshot?
		public var importedContent: Either<ProfileSnapshot, ProfileSnapshot.Header>?

		var isCloudProfileSyncEnabled: Bool {
			preferences?.security.isCloudProfileSyncEnabled == true
		}

		var shownInSettings: Bool {
			context == .settings
		}

		@PresentationState
		public var destination: Destinations.State?

		public var profileFilePotentiallyEncrypted: ExportableProfileFile?

		public init(
			context: Context,
			backupProfileHeaders: ProfileSnapshot.HeaderList? = nil,
			selectedProfileHeader: ProfileSnapshot.Header? = nil,
			isDisplayingFileImporter: Bool = false,
			isDisplayingFileExporter: Bool = false,
			thisDeviceID: UUID? = nil
		) {
			self.context = context
			self.backupProfileHeaders = backupProfileHeaders
			self.selectedProfileHeader = selectedProfileHeader
			self.isDisplayingFileImporter = isDisplayingFileImporter
			self.isDisplayingFileExporter = isDisplayingFileExporter
			self.thisDeviceID = thisDeviceID
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case cloudProfileSyncToggled(Bool)
		case selectedProfileHeader(ProfileSnapshot.Header?)
		case tappedImportProfile
		case exportProfileButtonTapped
		case dismissFileImporter
		case dismissFileExporter
		case profileImportResult(Result<URL, NSError>)
		case profileExportResult(Result<URL, NSError>)
		case tappedUseCloudBackup(ProfileSnapshot.Header)
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
			case importMnemonic(ImportMnemonic.State)
		}

		public enum Action: Sendable, Equatable {
			case confirmCloudSyncDisable(ConfirmCloudSyncDisable)
			case importMnemonic(ImportMnemonic.Action)
			case optionallyEncryptProfileBeforeExporting(SelectEncryptOrNot)

			public enum ConfirmCloudSyncDisable: Sendable, Hashable {
				case confirm
			}

			public enum SelectEncryptOrNot: Sendable, Hashable {
				case encrypt
				case doNotEncrypt
			}
		}

		public var body: some ReducerProtocol<State, Action> {
			Scope(state: /State.confirmCloudSyncDisable, action: /Action.confirmCloudSyncDisable) {
				EmptyReducer()
			}
			Scope(state: /State.importMnemonic, action: /Action.importMnemonic) {
				ImportMnemonic()
			}
			Scope(state: /State.optionallyEncryptProfileBeforeExporting, action: /Action.optionallyEncryptProfileBeforeExporting) {
				EmptyReducer()
			}
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

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.dataReader) var dataReader
	@Dependency(\.jsonDecoder) var jsonDecoder
	@Dependency(\.backupsClient) var backupsClient
	@Dependency(\.appPreferencesClient) var appPreferencesClient

	public init() {}

	public var body: some ReducerProtocolOf<ProfileBackups> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. /ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
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

		case let .tappedUseCloudBackup(profileHeader):
			state.importedContent = .right(profileHeader)
			showImportMnemonic(state: &state)
			return .none

		case .dismissFileImporter:
			state.isDisplayingFileImporter = false
			return .none

		case .dismissFileExporter:
			state.isDisplayingFileExporter = false
			return .none

		case let .profileImportResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .profileImportResult(.success(profileURL)):
			do {
				let data = try dataReader.contentsOf(profileURL, options: .uncached)
//				let snapshot = try jsonDecoder().decode(ProfileSnapshot.self, from: data)
				//                let
//				state.importedContent = .left(snapshot)
				let possiblyEncrypted = try ExportableProfileFile(data: data)
				//                state.importedContent = .left(snapshot)
				switch possiblyEncrypted {
				case let .encrypted(encrypted):
					state.importedEncryptedSnapshot = encrypted
					fatalError("prompt for encryption password and then `showImportMnemonic`")
				case let .plaintext(snapshhot):
					state.importedContent = .left(snapshhot)
					showImportMnemonic(state: &state)
				}
			} catch {
				errorQueue.schedule(error)
			}
			return .none

		case let .profileExportResult(.success(exportedProfileURL)):
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

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(.importMnemonic(.delegate(.savedInProfile(factorSource))))):
			guard let importedContent = state.importedContent else {
				assertionFailure("Imported mnemonic, but didn't import neither a snapshot or a profile header")
				return .none
			}

			return .run { [importedContent] send in
				switch importedContent {
				case let .left(snapshot):
					try await backupsClient.importProfileSnapshot(snapshot, factorSource.id)
				case let .right(header):
					try await backupsClient.importCloudProfile(header, factorSource.id)
				}
				await send(.delegate(.profileImported))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case .destination(.presented(.optionallyEncryptProfileBeforeExporting(.doNotEncrypt))):
			return exportProfile(encrypt: false, state: &state)

		case .destination(.presented(.optionallyEncryptProfileBeforeExporting(.encrypt))):
			return exportProfile(encrypt: true, state: &state)

		case .destination(.presented(.confirmCloudSyncDisable(.confirm))):
			state.destination = nil
			return updateCloudSync(state: &state, isEnabled: false)

		case .destination(.dismiss):
			state.destination = nil
			return .none
		default:
			return .none
		}
	}

	private func exportProfile(encrypt: Bool, state: inout State) -> EffectTask<Action> {
		if encrypt {
			fatalError("handle encrypt...")
			state.isDisplayingFileExporter = true
		} else {
			state.isDisplayingFileExporter = true
		}
		return .none
	}

	private func showImportMnemonic(state: inout State) {
		state.destination = .importMnemonic(.init(
			persistAsMnemonicKind: .onDevice(.babylon)
		))
	}

	private func updateCloudSync(state: inout State, isEnabled: Bool) -> EffectTask<Action> {
		state.preferences?.security.isCloudProfileSyncEnabled = isEnabled
		return .fireAndForget {
			try await appPreferencesClient.setIsCloudProfileSyncEnabled(false)
		}
	}
}

extension ProfileBackups {}

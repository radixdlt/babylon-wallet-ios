import AppPreferencesClient
import BackupsClient
import Cryptography
import FeaturePrelude
import ImportMnemonicFeature
import OverlayWindowClient

// MARK: - SelectBackup
public struct SelectBackup: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var backupProfileHeaders: ProfileSnapshot.HeaderList?
		public var selectedProfileHeader: ProfileSnapshot.Header?
		public var isDisplayingFileImporter: Bool

		public var thisDeviceID: UUID?

		public var importedContent: Either<ProfileSnapshot, ProfileSnapshot.Header>?

		@PresentationState
		public var destination: Destinations.State?

		public var profileFilePotentiallyEncrypted: ExportableProfileFile?

		public init(
			backupProfileHeaders: ProfileSnapshot.HeaderList? = nil,
			selectedProfileHeader: ProfileSnapshot.Header? = nil,
			isDisplayingFileImporter: Bool = false,
			thisDeviceID: UUID? = nil
		) {
			self.backupProfileHeaders = backupProfileHeaders
			self.selectedProfileHeader = selectedProfileHeader
			self.isDisplayingFileImporter = isDisplayingFileImporter
			self.thisDeviceID = thisDeviceID
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case selectedProfileHeader(ProfileSnapshot.Header?)
		case importFromFileInstead
		case dismissFileImporter
		case profileImportResult(Result<URL, NSError>)
		case tappedUseCloudBackup(ProfileSnapshot.Header)
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case importMnemonic(ImportMnemonic.State)
			case inputEncryptionPassword(EncryptOrDecryptProfile.State)
		}

		public enum Action: Sendable, Equatable {
			case importMnemonic(ImportMnemonic.Action)
			case inputEncryptionPassword(EncryptOrDecryptProfile.Action)
		}

		public var body: some ReducerProtocol<State, Action> {
			Scope(state: /State.inputEncryptionPassword, action: /Action.inputEncryptionPassword) {
				EncryptOrDecryptProfile()
			}
			Scope(state: /State.importMnemonic, action: /Action.importMnemonic) {
				ImportMnemonic()
			}
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case loadBackupProfileHeadersResult(ProfileSnapshot.HeaderList?)
		case loadThisDeviceIDResult(UUID?)
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
	@Dependency(\.overlayWindowClient) var overlayWindowClient

	public init() {}

	public var body: some ReducerProtocolOf<SelectBackup> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. /ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .task:
			return .run { send in
				await send(.internal(.loadThisDeviceIDResult(
					backupsClient.loadDeviceID()
				)))

				await send(.internal(.loadBackupProfileHeadersResult(
					backupsClient.loadProfileBackups()
				)))
			}

		case .importFromFileInstead:
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

		case let .profileImportResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .profileImportResult(.success(profileURL)):
			do {
				guard profileURL.startAccessingSecurityScopedResource() else {
					throw LackedPermissionToAccessSecurityScopedResource()
				}
				defer { profileURL.stopAccessingSecurityScopedResource() }
				let data = try dataReader.contentsOf(profileURL, options: .uncached)
				let possiblyEncrypted = try ExportableProfileFile(data: data)
				switch possiblyEncrypted {
				case let .encrypted(encrypted):
					state.destination = .inputEncryptionPassword(.init(mode: .decrypt(encrypted)))
					return .none

				case let .plaintext(snapshot):
					importing(snapshot: snapshot, state: &state)
				}
			} catch {
				errorQueue.schedule(error)
				loggerGlobal.error("Failed to import profile, error: \(error)")
			}
			return .none
		}
	}

	private func importing(snapshot: ProfileSnapshot, state: inout State) {
		state.importedContent = .left(snapshot)
		showImportMnemonic(state: &state)
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadBackupProfileHeadersResult(profileHeaders):
			state.backupProfileHeaders = profileHeaders
			return .none

		case let .loadThisDeviceIDResult(identifier):
			state.thisDeviceID = identifier
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
			loggerGlobal.notice("Starting import snapshot process...")
			return .run { [importedContent] send in
				switch importedContent {
				case let .left(snapshot):
					loggerGlobal.notice("Importing snapshot...")
					try await backupsClient.importProfileSnapshot(snapshot, factorSource.id)
				case let .right(header):
					try await backupsClient.importCloudProfile(header, factorSource.id)
				}
				await send(.delegate(.profileImported))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case .destination(.presented(.inputEncryptionPassword(.delegate(.dismiss)))):
			state.destination = nil
			return .none

		case let .destination(.presented(.inputEncryptionPassword(.delegate(.successfullyDecrypted(_, decrypted))))):
			state.destination = nil
			overlayWindowClient.scheduleHUD(.init(kind: .decryptedProfile))
			importing(snapshot: decrypted, state: &state)
			return .none

		case .destination(.presented(.inputEncryptionPassword(.delegate(.successfullyEncrypted)))):
			preconditionFailure("What? Encrypted? Expected to only have DECRYPTED. Incorrect implementation somewhere...")
			return .none

		case .destination(.dismiss):
			state.destination = nil
			return .none

		default:
			return .none
		}
	}

	private func showImportMnemonic(state: inout State) {
		state.destination = .importMnemonic(.init(
			isWordCountFixed: true,
			persistAsMnemonicKind: .intoKeychainOnly,
			wordCount: .twentyFour
		))
	}
}

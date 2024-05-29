import ComposableArchitecture
import SwiftUI

// MARK: - SelectBackup
public struct SelectBackup: Sendable, FeatureReducer {
	public struct State: Hashable, Sendable {
		public enum Status: Hashable, Sendable {
			case start
			case migrating
			case loading
			case loaded
			case failed
		}

		public var status: Status = .start

		public var backedUpProfiles: [CloudBackupClient.BackedupProfile]? = nil

		public var selectedProfile: CloudBackupClient.BackedupProfile? = nil

		public var isDisplayingFileImporter: Bool
		public var thisDeviceID: UUID?

		@PresentationState
		public var destination: Destination.State?

		public var profileFile: ExportableProfileFile?

		public init(
			isDisplayingFileImporter: Bool = false,
			thisDeviceID: UUID? = nil
		) {
			self.isDisplayingFileImporter = isDisplayingFileImporter
			self.thisDeviceID = thisDeviceID
		}
	}

	public struct Destination: DestinationReducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case inputEncryptionPassword(EncryptOrDecryptProfile.State)
			case recoverWalletWithoutProfileCoordinator(RecoverWalletWithoutProfileCoordinator.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case inputEncryptionPassword(EncryptOrDecryptProfile.Action)
			case recoverWalletWithoutProfileCoordinator(RecoverWalletWithoutProfileCoordinator.Action)
		}

		public var body: some Reducer<State, Action> {
			Scope(state: \.inputEncryptionPassword, action: \.inputEncryptionPassword) {
				EncryptOrDecryptProfile()
			}
			Scope(state: \.recoverWalletWithoutProfileCoordinator, action: \.recoverWalletWithoutProfileCoordinator) {
				RecoverWalletWithoutProfileCoordinator()
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case selectedProfile(CloudBackupClient.BackedupProfile?)
		case importFromFileInstead
		case dismissFileImporter
		case otherRestoreOptionsTapped
		case profileImportResult(Result<URL, NSError>)
		case tappedUseCloudBackup(CloudBackupClient.BackedupProfile)
		case closeButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case setStatus(State.Status)
		case loadCloudBackupProfiles([CloudBackupClient.BackedupProfile]?)
		case loadThisDeviceIDResult(UUID?)
	}

	public enum DelegateAction: Sendable, Equatable {
		case selectedProfile(Profile, isInCloud: Bool, containsLegacyP2PLinks: Bool)
		case backToStartOfOnboarding
		case profileCreatedFromImportedBDFS
	}

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.dataReader) var dataReader
	@Dependency(\.jsonDecoder) var jsonDecoder
	@Dependency(\.cloudBackupClient) var cloudBackupClient
	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.secureStorageClient) var secureStorageClient
	@Dependency(\.userDefaults) var userDefaults

	public init() {}

	public var body: some ReducerOf<SelectBackup> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return migrateEffect()
				.concatenate(with: loadEffect())

		case .importFromFileInstead:
			state.isDisplayingFileImporter = true
			return .none

		case .otherRestoreOptionsTapped:
			state.destination = .recoverWalletWithoutProfileCoordinator(.init())
			return .none

		case let .selectedProfile(profile):
			state.selectedProfile = profile
			return .none

		case let .tappedUseCloudBackup(backedupProfile):
			return .send(.delegate(.selectedProfile(backedupProfile.profile, isInCloud: true, containsLegacyP2PLinks: backedupProfile.containsLegacyP2PLinks)))

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

				case let .plaintext(profile):
					let containsP2PLinks = Profile.checkIfProfileJsonContainsLegacyP2PLinks(contents: data)
					return .send(.delegate(.selectedProfile(profile, isInCloud: false, containsLegacyP2PLinks: containsP2PLinks)))
				}
			} catch {
				errorQueue.schedule(error)
				loggerGlobal.error("Failed to import profile, error: \(error)")
			}
			return .none

		case .closeButtonTapped:
			return .run { _ in
				await dismiss()
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setStatus(status):
			state.status = status
			return .none

		case let .loadCloudBackupProfiles(profiles):
			state.backedUpProfiles = profiles?.sorted(by: \.profile.header.lastModified).reversed()
			return .none

		case let .loadThisDeviceIDResult(identifier):
			state.thisDeviceID = identifier
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .recoverWalletWithoutProfileCoordinator(.delegate(.dismiss)):
			state.destination = nil
			return .none

		case .recoverWalletWithoutProfileCoordinator(.delegate(.backToStartOfOnboarding)):
			state.destination = nil
			return .send(.delegate(.backToStartOfOnboarding))

		case .recoverWalletWithoutProfileCoordinator(.delegate(.profileCreatedFromImportedBDFS)):
			state.destination = nil
			// Unfortunately we need a short delay :/ otherwise the "Recovery Completed" screen pops back again,
			// SwiftUI nav bug...
			return delayedShortEffect(for: .delegate(.profileCreatedFromImportedBDFS))

		case .inputEncryptionPassword(.delegate(.dismiss)):
			state.destination = nil
			return .none

		case let .inputEncryptionPassword(.delegate(.successfullyDecrypted(_, decrypted, containsP2PLinks))):
			state.destination = nil
			overlayWindowClient.scheduleHUD(.decryptedProfile)
			return .send(.delegate(.selectedProfile(decrypted, isInCloud: false, containsLegacyP2PLinks: containsP2PLinks)))

		case .inputEncryptionPassword(.delegate(.successfullyEncrypted)):
			preconditionFailure("Incorrect implementation, expected decryption")

		default:
			return .none
		}
	}

	public func reduceDismissedDestination(into state: inout State) -> Effect<Action> {
		state.destination = nil
		return .none
	}

	public func migrateEffect() -> Effect<Action> {
		.run { send in
			if !userDefaults.getDidMigrateKeychainProfiles {
				await send(.internal(.setStatus(.migrating)))
				do {
					let profilesInKeychain = try secureStorageClient.loadProfileHeaderList()?.count ?? 0
					if profilesInKeychain > 0 {
						_ = try await cloudBackupClient.migrateProfilesFromKeychain()
						userDefaults.setDidMigrateKeychainProfiles(true)
					}
				} catch {
					await send(.internal(.setStatus(.failed)))
				}
			}
		}
	}

	public func loadEffect() -> Effect<Action> {
		.run { send in
			do {
				await send(.internal(.loadThisDeviceIDResult(
					cloudBackupClient.loadDeviceID()
				)))

				await send(.internal(.setStatus(.loading)))

				try await send(.internal(.loadCloudBackupProfiles(
					cloudBackupClient.loadAllProfiles()
				)))

				await send(.internal(.setStatus(.loaded)))
			} catch {
				await send(.internal(.setStatus(.failed)))
			}
		}
	}
}

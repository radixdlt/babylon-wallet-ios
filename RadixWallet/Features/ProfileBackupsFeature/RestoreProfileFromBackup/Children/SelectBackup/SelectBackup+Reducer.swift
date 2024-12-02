import CloudKit
import ComposableArchitecture
import SwiftUI

// MARK: - SelectBackup
struct SelectBackup: Sendable, FeatureReducer {
	struct State: Hashable, Sendable {
		enum Status: Hashable, Sendable {
			case start
			case migrating
			case loading
			case loaded
			case failed(FailureReason)

			enum FailureReason: Sendable {
				case networkUnavailable
				case accountTemporarilyUnavailable
				case notAuthenticated
				case other
			}
		}

		var status: Status = .start

		var backedUpProfiles: [Profile.Header]? = nil

		var selectedProfile: Profile.Header? = nil

		var isDisplayingFileImporter: Bool
		var thisDeviceID: UUID?

		@PresentationState
		var destination: Destination.State?

		var profileFile: ExportableProfileFile?

		init(
			isDisplayingFileImporter: Bool = false,
			thisDeviceID: UUID? = nil
		) {
			self.isDisplayingFileImporter = isDisplayingFileImporter
			self.thisDeviceID = thisDeviceID
		}
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case inputEncryptionPassword(EncryptOrDecryptProfile.State)
			case recoverWalletWithoutProfileCoordinator(RecoverWalletWithoutProfileCoordinator.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case inputEncryptionPassword(EncryptOrDecryptProfile.Action)
			case recoverWalletWithoutProfileCoordinator(RecoverWalletWithoutProfileCoordinator.Action)
		}

		var body: some Reducer<State, Action> {
			Scope(state: \.inputEncryptionPassword, action: \.inputEncryptionPassword) {
				EncryptOrDecryptProfile()
			}
			Scope(state: \.recoverWalletWithoutProfileCoordinator, action: \.recoverWalletWithoutProfileCoordinator) {
				RecoverWalletWithoutProfileCoordinator()
			}
		}
	}

	enum ViewAction: Sendable, Equatable {
		case task
		case selectedProfile(Profile.Header?)
		case importFromFileInstead
		case dismissFileImporter
		case otherRestoreOptionsTapped
		case profileImportResult(Result<URL, NSError>)
		case tappedUseCloudBackup(ProfileID)
		case closeButtonTapped
	}

	enum InternalAction: Sendable, Equatable {
		case setStatus(State.Status)
		case loadedProfileHeadersFromCloudBackup([Profile.Header]?)
		case loadedThisDeviceID(UUID?)
	}

	enum DelegateAction: Sendable, Equatable {
		case selectedProfile(Profile, containsLegacyP2PLinks: Bool)
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

	init() {}

	var body: some ReducerOf<SelectBackup> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return migrateAndLoadEffect()

		case .importFromFileInstead:
			state.isDisplayingFileImporter = true
			return .none

		case .otherRestoreOptionsTapped:
			state.destination = .recoverWalletWithoutProfileCoordinator(.init())
			return .none

		case let .selectedProfile(profile):
			state.selectedProfile = profile
			return .none

		case let .tappedUseCloudBackup(profileID):
			return .run { send in
				do {
					let backedUpProfile = try await cloudBackupClient.loadProfile(profileID)
					await send(.delegate(.selectedProfile(backedUpProfile.profile, containsLegacyP2PLinks: backedUpProfile.containsLegacyP2PLinks)))
				} catch {
					errorQueue.schedule(error)
				}
			}

		case .dismissFileImporter:
			state.isDisplayingFileImporter = false
			return .none

		case let .profileImportResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .profileImportResult(.success(profileURL)):
			do {
				guard profileURL.startAccessingSecurityScopedResource() else {
					struct LackedPermissionToAccessSecurityScopedResource: Error {}
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
					return .send(.delegate(.selectedProfile(profile, containsLegacyP2PLinks: containsP2PLinks)))
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

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setStatus(status):
			state.status = status
			return .none

		case let .loadedProfileHeadersFromCloudBackup(headers):
			state.backedUpProfiles = headers?.sorted(by: \.lastModified).reversed()
			return .none

		case let .loadedThisDeviceID(identifier):
			state.thisDeviceID = identifier
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
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
			return delayedShortEffect(for: .delegate(.selectedProfile(decrypted, containsLegacyP2PLinks: containsP2PLinks)))

		case .inputEncryptionPassword(.delegate(.successfullyEncrypted)):
			preconditionFailure("Incorrect implementation, expected decryption")

		default:
			return .none
		}
	}

	func reduceDismissedDestination(into state: inout State) -> Effect<Action> {
		state.destination = nil
		return .none
	}

	func migrateAndLoadEffect() -> Effect<Action> {
		.run { send in
			do {
				await send(.internal(.setStatus(.migrating)))
				_ = try await cloudBackupClient.migrateProfilesFromKeychain()

				try await send(.internal(.loadedThisDeviceID(
					secureStorageClient.loadDeviceInfo()?.id
				)))

				await send(.internal(.setStatus(.loading)))

				try await send(.internal(.loadedProfileHeadersFromCloudBackup(
					cloudBackupClient.loadProfileHeaders()
				)))

				await send(.internal(.setStatus(.loaded)))
			} catch {
				let reason: State.Status.FailureReason
				switch error {
				case CKError.accountTemporarilyUnavailable:
					reason = .accountTemporarilyUnavailable
				case CKError.notAuthenticated:
					reason = .notAuthenticated
				case CKError.networkUnavailable, CKError.networkFailure:
					reason = .networkUnavailable
				default:
					reason = .other
					errorQueue.schedule(error)
				}

				loggerGlobal.error("Failed to migrate or load backed up profiles, error: \(error)")
				await send(.internal(.setStatus(.failed(reason))))
			}
		}
	}
}

import ClientPrelude
import LocalAuthenticationClient // read LA config to specify max security of new items.
import Profile
import Resources // L10n for auth prompt

// MARK: - KeychainAccess.Accessibility + Sendable
extension KeychainAccess.Accessibility: @unchecked Sendable {}

// MARK: - KeychainAccess.AuthenticationPolicy + Sendable
extension KeychainAccess.AuthenticationPolicy: @unchecked Sendable {}

// MARK: - SecureStorageError
public enum SecureStorageError: Swift.Error, Equatable {
	case evaluateLocalAuthenticationFailed(reason: LocalAuthenticationClient.Error)
	case evaluateLocalAuthenticationFailedUnknown(reason: String)
	case passcodeNotSet
}

func importantKeychainIdentifier(_ msg: String) -> Tagged<KeychainClient, NonEmptyString>? {
	var msg = msg
	#if DEBUG
	msg += " DEBUG"
	#endif
	guard let nonEmpty = NonEmptyString(rawValue: msg) else {
		return nil
	}
	return .init(rawValue: nonEmpty)
}

// MARK: - SecureStorageClient + DependencyKey
extension SecureStorageClient: DependencyKey {
	public typealias Value = SecureStorageClient

	public static let liveValue: Self = {
		@Dependency(\.keychainClient) var keychainClient
		@Dependency(\.jsonEncoder) var jsonEncoder
		@Dependency(\.jsonDecoder) var jsonDecoder
		@Dependency(\.localAuthenticationClient) var localAuthenticationClient
		@Dependency(\.uuid) var uuid
		@Dependency(\.assertionFailure) var assertionFailure

		struct AccesibilityAndAuthenticationPolicy: Sendable, Equatable {
			/// The most secure currently available accessibility
			let accessibility: KeychainAccess.Accessibility

			/// The most secure currently available AuthenticationPolicy, if any.
			let authenticationPolicy: AuthenticationPolicy?
		}

		@Sendable func queryMostSecureAccesibilityAndAuthenticationPolicy() async throws -> AccesibilityAndAuthenticationPolicy {
			let config: LocalAuthenticationConfig
			do {
				config = try await localAuthenticationClient.queryConfig()
			} catch let failure as LocalAuthenticationClient.Error {
				throw SecureStorageError.evaluateLocalAuthenticationFailed(reason: failure)
			} catch {
				throw SecureStorageError.evaluateLocalAuthenticationFailedUnknown(reason: String(describing: error))
			}

			guard config.isPasscodeSetUp else {
				throw SecureStorageError.passcodeNotSet
			}

			// we know that user has `passcode` enabled, thus we will use `.whenPasscodeSetThisDeviceOnly`
			// BEWARE! If the user deletes the passcode any item protected by this `accessibility` WILL GET DELETED.
			// We use `userPresence` always, disregardong of biometrics being setup up or not,
			// to allow user to be able to fallback to passcode if biometrics.
			return .init(accessibility: .whenPasscodeSetThisDeviceOnly, authenticationPolicy: .userPresence)
		}

		let loadProfileSnapshotData: LoadProfileSnapshotData = { id in
			try await keychainClient.getDataWithoutAuth(forKey: id.keychainKey)
		}

		let deleteMnemonicByFactorSourceID: DeleteMnemonicByFactorSourceID = { factorSourceID in
			let key = key(factorSourceID: factorSourceID)
			try await keychainClient.removeData(forKey: key)
		}

		@Sendable func saveProfile(
			snapshotData data: Data,
			key: KeychainClient.Key,
			iCloudSyncEnabled: Bool
		) async throws {
			try await keychainClient.setDataWithoutAuth(
				data,
				forKey: key,
				attributes: .init(
					iCloudSyncEnabled: iCloudSyncEnabled,
					accessibility: .whenUnlocked, // do not delete the Profile if passcode gets deleted.
					label: importantKeychainIdentifier("Radix Wallet Data"),
					comment: "Contains your accounts, personas, authorizedDapps, linked connector extensions and wallet app preferences."
				)
			)
		}

		@Sendable func saveProfile(
			snapshot profileSnapshot: ProfileSnapshot,
			iCloudSyncEnabled: Bool
		) async throws {
			let data = try jsonEncoder().encode(profileSnapshot)
			try await saveProfile(snapshotData: data, key: profileSnapshot.header.id.keychainKey, iCloudSyncEnabled: iCloudSyncEnabled)
		}

		@Sendable func loadProfileHeaderList() async throws -> ProfileSnapshot.HeaderList? {
			try await keychainClient
				.getDataWithoutAuth(forKey: profileHeaderListKeychainKey)
				.map {
					try jsonDecoder().decode([ProfileSnapshot.Header].self, from: $0)
				}
				.flatMap(ProfileSnapshot.HeaderList.init)
		}

		@Sendable func saveProfileHeaderList(_ headers: ProfileSnapshot.HeaderList) async throws {
			let data = try jsonEncoder().encode(headers)
			try await keychainClient.setDataWithoutAuth(
				data,
				forKey: profileHeaderListKeychainKey,
				attributes: .init(
					iCloudSyncEnabled: true, // Always synced, since header list might be used by multiple devices
					accessibility: .whenUnlocked,
					label: importantKeychainIdentifier("Radix Wallet Metadata"),
					comment: "Contains the metadata about Radix Wallet Data."
				)
			)
		}

		@Sendable func deleteProfileHeader(_ id: ProfileSnapshot.Header.ID) async throws {
			if let profileHeaders = try await loadProfileHeaderList() {
				let remainingHeaders = profileHeaders.filter { $0.id != id }
				if remainingHeaders.isEmpty {
					// Delete the list instea of keeping an empty list
					try await deleteProfileHeaderList()
				} else {
					try await saveProfileHeaderList(.init(remainingHeaders)!)
				}
			}
		}

		@Sendable func deleteProfileHeaderList() async throws {
			try await keychainClient.removeData(forKey: profileHeaderListKeychainKey)
		}

		@Sendable func deleteProfile(_ id: ProfileSnapshot.Header.ID, iCloudSyncEnabled: Bool) async throws {
			try await keychainClient.removeData(forKey: id.keychainKey)
			try await deleteProfileHeader(id)
		}

		@Sendable func loadDeviceIdentifier() async throws -> UUID? {
			let loaded = try await keychainClient
				.getDataWithoutAuth(forKey: deviceIdentifierKey)
				.map {
					try jsonDecoder().decode(UUID.self, from: $0)
				}

			if let loaded {
				loggerGlobal.trace("Loaded deviceIdentifier: \(loaded)")
			} else {
				loggerGlobal.info("No deviceIdentifier loaded, was nil.")
			}
			return loaded
		}

		@Sendable func saveDeviceIdentifier(_ deviceIdentifier: UUID) async throws {
			let data = try jsonEncoder().encode(deviceIdentifier)
			try await keychainClient.setDataWithoutAuth(
				data,
				forKey: deviceIdentifierKey,
				attributes: .init(
					iCloudSyncEnabled: false, // Never ever synced, since related to this device only..
					accessibility: .whenUnlocked,
					label: importantKeychainIdentifier("Radix Wallet device identifier"),
					comment: "The unique identifier of this device"
				)
			)
			loggerGlobal.notice("Saved deviceIdentifier: \(deviceIdentifier)")
		}

		return Self(
			saveProfileSnapshot: { profileSnapshot in
				let data = try jsonEncoder().encode(profileSnapshot)
				try await saveProfile(
					snapshotData: data,
					key: profileSnapshot.header.id.keychainKey,
					iCloudSyncEnabled: profileSnapshot.appPreferences.security.isCloudProfileSyncEnabled
				)
			},
			loadProfileSnapshotData: loadProfileSnapshotData,
			saveMnemonicForFactorSource: { privateFactorSource in
				let factorSource = privateFactorSource.factorSource
				let mnemonicWithPassphrase = privateFactorSource.mnemonicWithPassphrase
				let data = try jsonEncoder().encode(mnemonicWithPassphrase)
				let mostSecureAccesibilityAndAuthenticationPolicy = try await queryMostSecureAccesibilityAndAuthenticationPolicy()
				let key = key(factorSourceID: factorSource.id)

				try await keychainClient.setDataWithAuth(
					data,
					forKey: key,
					attributes: .init(
						iCloudSyncEnabled: false,
						accessibility: mostSecureAccesibilityAndAuthenticationPolicy.accessibility,
						authenticationPolicy: mostSecureAccesibilityAndAuthenticationPolicy.authenticationPolicy,
						label: importantKeychainIdentifier("Radix Wallet Factor Secret"),
						comment: .init("Created on \(factorSource.hint.name) \(factorSource.supportsOlympia ? " (Olympia)" : "")")
					)
				)
			},
			loadMnemonicByFactorSourceID: { factorSourceID, purpose in
				let key = key(factorSourceID: factorSourceID)
				let authPromptValue: String = {
					switch purpose {
					case let .createEntity(kind):
						let entityKindName = kind == .account ? L10n.Common.account : L10n.Common.persona
						return L10n.Biometrics.Prompt.creationOfEntity(entityKindName)
					case .signTransaction:
						return L10n.Biometrics.Prompt.signTransaction
					case .signAuthChallenge:
						return L10n.Biometrics.Prompt.signAuthChallenge
					case .displaySeedPhrase:
						return L10n.Biometrics.Prompt.displaySeedPhrase
					case .createSignAuthKey:
						return L10n.Biometrics.Prompt.createSignAuthKey
					case .importOlympiaAccounts:
						return L10n.Biometrics.Prompt.importOlympiaAccounts
					case .checkingAccounts:
						return L10n.Biometrics.Prompt.checkingAccounts

					case .updateAccountMetadata:
						// This is debug only... for now.
						return L10n.Biometrics.Prompt.updateAccountMetadata
					}
				}()
				let authenticationPrompt: KeychainClient.AuthenticationPrompt = NonEmptyString(rawValue: authPromptValue).map { KeychainClient.AuthenticationPrompt($0) } ?? "Authenticate to wallet data secret."
				guard let data = try await keychainClient.getDataWithAuth(
					forKey: key,
					authenticationPrompt: authenticationPrompt
				) else {
					return nil
				}
				return try jsonDecoder().decode(MnemonicWithPassphrase.self, from: data)
			},
			deleteMnemonicByFactorSourceID: deleteMnemonicByFactorSourceID,
			deleteProfileAndMnemonicsByFactorSourceIDs: { profileID, keepInICloudIfPresent in
				guard let profileSnapshotData = try await loadProfileSnapshotData(profileID) else {
					return
				}

				guard let profileSnapshot = try? jsonDecoder().decode(ProfileSnapshot.self, from: profileSnapshotData) else {
					return
				}

				// We want to keep the profile backup in iCloud.
				if !(profileSnapshot.appPreferences.security.isCloudProfileSyncEnabled && keepInICloudIfPresent) {
					try await deleteProfile(profileID, iCloudSyncEnabled: profileSnapshot.appPreferences.security.isCloudProfileSyncEnabled)
				}

				for factorSourceID in profileSnapshot
					.factorSources
					.compactMap({ try? $0.extract(as: DeviceFactorSource.self) })
					.map(\.id)
				{
					loggerGlobal.debug("Deleting factor source with ID: \(factorSourceID)")
					try await deleteMnemonicByFactorSourceID(factorSourceID)
				}
			},
			updateIsCloudProfileSyncEnabled: { profileId, change in
				guard
					let profileSnapshotData = try await loadProfileSnapshotData(profileId),
					let headerList = try await loadProfileHeaderList()
				else {
					return
				}

				switch change {
				case .disable:
					loggerGlobal.notice("Disabling iCloud sync of Profile snapshot (which should also delete it from iCloud)")
					try await saveProfile(snapshotData: profileSnapshotData, key: profileId.keychainKey, iCloudSyncEnabled: false)
				case .enable:
					loggerGlobal.notice("Enabling iCloud sync of Profile snapshot")
					try await saveProfile(snapshotData: profileSnapshotData, key: profileId.keychainKey, iCloudSyncEnabled: true)
				}
			},
			loadProfileHeaderList: loadProfileHeaderList,
			saveProfileHeaderList: saveProfileHeaderList,
			deleteProfileHeaderList: deleteProfileHeaderList,
			loadDeviceIdentifier: loadDeviceIdentifier,
			saveDeviceIdentifier: saveDeviceIdentifier
		)
	}()
}

extension SecureStorageClient {
	public func loadProfileSnapshot(_ id: ProfileSnapshot.Header.ID) async throws -> ProfileSnapshot? {
		@Dependency(\.jsonDecoder) var jsonDecoder
		guard
			let existingSnapshotData = try await loadProfileSnapshotData(id)
		else {
			return nil
		}
		return try jsonDecoder().decode(ProfileSnapshot.self, from: existingSnapshotData)
	}

	public func loadProfile(_ id: ProfileSnapshot.Header.ID) async throws -> Profile? {
		@Dependency(\.jsonDecoder) var jsonDecoder
		guard
			let existingSnapshot = try await loadProfileSnapshot(id)
		else {
			return nil
		}
		return try Profile(snapshot: existingSnapshot)
	}
}

private let profileHeaderListKeychainKey: KeychainClient.Key = "profileHeaderList"
private let deviceIdentifierKey: KeychainClient.Key = "deviceIdentifier"

extension ProfileSnapshot.Header.ID {
	private static let profileSnapshotKeychainKeyPrefix = "profileSnapshot"

	var keychainKey: KeychainClient.Key {
		"\(Self.profileSnapshotKeychainKeyPrefix) - \(uuidString)"
	}
}

private func key(factorSourceID: FactorSourceID.FromHash) -> KeychainClient.Key {
	.init(rawValue: .init(rawValue: factorSourceID.keychainKey)!)
}

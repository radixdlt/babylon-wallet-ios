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

// MARK: - SecureStorageClient + DependencyKey
extension SecureStorageClient: DependencyKey {
	public typealias Value = SecureStorageClient

	public static let liveValue: Self = {
		@Dependency(\.keychainClient) var keychainClient
		@Dependency(\.jsonEncoder) var jsonEncoder
		@Dependency(\.jsonDecoder) var jsonDecoder
		@Dependency(\.localAuthenticationClient) var localAuthenticationClient

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
			try await keychainClient.getDataWithoutAuthForKey(id.keychainKey)
		}

		let deleteMnemonicByFactorSourceID: DeleteMnemonicByFactorSourceID = { factorSourceID in
			let key = key(factorSourceID: factorSourceID)
			try await keychainClient.removeDataForKey(key)
		}

		@Sendable func saveProfile(
			snapshotData data: Data,
			key: KeychainClient.Key,
			iCloudSyncEnabled: Bool
		) async throws {
			try await keychainClient.setDataWithoutAuthForKey(
				KeychainClient.SetItemWithoutAuthRequest(
					data: data,
					key: key,
					iCloudSyncEnabled: iCloudSyncEnabled,
					accessibility: .whenUnlocked, // do not delete the Profile if passcode gets deleted.
					label: "Radix Wallet Data",
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

		return Self(
			saveProfileSnapshot: { profileSnapshot in
				let data = try jsonEncoder().encode(profileSnapshot)
				try await keychainClient.setDataWithoutAuthForKey(
					KeychainClient.SetItemWithoutAuthRequest(
						data: data,
						key: profileSnapshot.header.id.keychainKey,
						iCloudSyncEnabled: profileSnapshot.appPreferences.security.isCloudProfileSyncEnabled,
						accessibility: .whenUnlocked, // do not delete the Profile if passcode gets deleted.
						label: "Radix Wallet Data",
						comment: "Contains your accounts, personas, authorizedDapps, linked connector extensions and wallet app preferences."
					)
				)
			},
			loadProfileSnapshotData: loadProfileSnapshotData,
			saveMnemonicForFactorSource: { privateFactorSource in
				let factorSource = privateFactorSource.hdOnDeviceFactorSource.factorSource
				let mnemonicWithPassphrase = privateFactorSource.mnemonicWithPassphrase
				let data = try jsonEncoder().encode(mnemonicWithPassphrase)
				let mostSecureAccesibilityAndAuthenticationPolicy = try await queryMostSecureAccesibilityAndAuthenticationPolicy()
				let key = key(factorSourceID: factorSource.id)

				try await keychainClient.setDataWithAuthenticationPolicyIfAble(
					data: data,
					key: key,
					iCloudSyncEnabled: false, // We do NOT want to sync this to iCloud, ever.
					accessibility: mostSecureAccesibilityAndAuthenticationPolicy.accessibility,
					authenticationPolicy: mostSecureAccesibilityAndAuthenticationPolicy.authenticationPolicy, // can be nil
					label: "Radix Wallet Factor Secret",
					comment: .init("Created on \(factorSource.description.rawValue) \(factorSource.supportsOlympia ? " (Olympia)" : "")")
				)
			},
			loadMnemonicByFactorSourceID: { factorSourceID, purpose in
				let key = key(factorSourceID: factorSourceID)
				let authPromptValue: String = {
					switch purpose {
					case let .createEntity(kind):
						let entityKindName = kind == .account ? L10n.Common.Account.kind : L10n.Common.Persona.kind
						return L10n.Common.BiometricsPrompt.creationOfEntity(entityKindName)
					case .signTransaction: return L10n.Common.BiometricsPrompt.signTransaction
					case .signAuthChallenge: return L10n.Common.BiometricsPrompt.signAuthChallenge
					case .checkingAccounts: return L10n.Common.BiometricsPrompt.checkingAccounts
					case .createSignAuthKey: return "Create Auth signing key"
					#if DEBUG
					case .debugOnlyInspect: return "Auth to inspect mnemonic in ProfileView."
					#endif
					case .importOlympiaAccounts:
						return L10n.Common.BiometricsPrompt.importOlympiaAccounts
					}
				}()
				let authPrompt: KeychainClient.AuthenticationPrompt = NonEmptyString(rawValue: authPromptValue).map { KeychainClient.AuthenticationPrompt($0) } ?? "Authenticate to wallet data secret."
				guard let data = try await keychainClient.getDataWithAuthForKey(key, authPrompt) else {
					return nil
				}
				return try jsonDecoder().decode(MnemonicWithPassphrase.self, from: data)
			},
			deleteMnemonicByFactorSourceID: deleteMnemonicByFactorSourceID,
			deleteProfileAndMnemonicsByFactorSourceIDs: { profileID, keepIcloudIfPresent in
				guard let profileSnapshotData = try await loadProfileSnapshotData(profileID) else {
					return
				}
				if !keepIcloudIfPresent {
					try await keychainClient.removeDataForKey(profileID.keychainKey)
				}
				guard let profileSnapshot = try? jsonDecoder().decode(ProfileSnapshot.self, from: profileSnapshotData) else {
					return
				}
				if keepIcloudIfPresent {
					if profileSnapshot.appPreferences.security.isDeveloperModeEnabled {
						loggerGlobal.notice("Keeping Profile snapshot in Keychain and thus iCloud (keepIcloudIfPresent=\(keepIcloudIfPresent))")
					} else {
						loggerGlobal.notice("Deleting Profile snapshot from keychain since iCloud was not enabled any way. (keepIcloudIfPresent=\(keepIcloudIfPresent))")
						try await keychainClient.removeDataForKey(profileID.keychainKey)
					}
				}
				for factorSourceID in profileSnapshot.factorSources.map(\.id) {
					loggerGlobal.debug("Deleting factor source with ID: \(factorSourceID)")
					try await deleteMnemonicByFactorSourceID(factorSourceID)
				}
			},
			updateIsCloudProfileSyncEnabled: { profileId, change in
				guard
					let profileSnapshotData = try await loadProfileSnapshotData(profileId)
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
			loadProfileHeaderList: {
				try await keychainClient
					.getDataWithoutAuthForKey(profileHeaderListKeychainKey)
					.map {
						try jsonDecoder().decode([ProfileSnapshot.Header].self, from: $0)
					}.flatMap {
						.init($0)
					}
			},
			saveProfileHeaderList: { list in
				let data = try jsonEncoder().encode(list)
				try await keychainClient.setDataWithoutAuthForKey(
					KeychainClient.SetItemWithoutAuthRequest(
						data: data,
						key: profileHeaderListKeychainKey,
						iCloudSyncEnabled: true,
						accessibility: .whenUnlocked, // do not delete the Profile if passcode gets deleted.
						label: "Radix Wallet Metadata",
						comment: "Contains the metadata about Radix Wallet Data."
					)
				)
			},
			deleteProfileHeaderList: {
				try await keychainClient.removeDataForKey(profileHeaderListKeychainKey)
			}
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

extension ProfileSnapshot.Header.ID {
	private static let profileSnapshotKeychainKeyPrefix = "profileSnapshot"

	var keychainKey: KeychainClient.Key {
		"\(Self.profileSnapshotKeychainKeyPrefix) - \(uuidString)"
	}
}

private func key(factorSourceID: FactorSource.ID) -> KeychainClient.Key {
	.init(rawValue: .init(rawValue: factorSourceID.hexCodable.hex())!)
}

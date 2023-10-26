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
		@Dependency(\.overlayWindowClient) var overlayWindowClient

		struct AccesibilityAndAuthenticationPolicy: Sendable, Equatable {
			/// The most secure currently available accessibility
			let accessibility: KeychainAccess.Accessibility

			/// The most secure currently available AuthenticationPolicy, if any.
			let authenticationPolicy: AuthenticationPolicy?
		}

		@Sendable func queryMostSecureAccesibilityAndAuthenticationPolicy() throws -> AccesibilityAndAuthenticationPolicy {
			let config: LocalAuthenticationConfig
			do {
				config = try localAuthenticationClient.queryConfig()
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
			try keychainClient.getDataWithoutAuth(forKey: id.keychainKey)
		}

		let deleteMnemonicByFactorSourceID: DeleteMnemonicByFactorSourceID = { factorSourceID in
			let key = key(factorSourceID: factorSourceID)
			try keychainClient.removeData(forKey: key)
		}

		@Sendable func saveProfile(
			snapshotData data: Data,
			key: KeychainClient.Key,
			iCloudSyncEnabled: Bool
		) throws {
			try keychainClient.setDataWithoutAuth(
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
		) throws {
			let data = try jsonEncoder().encode(profileSnapshot)
			try saveProfile(snapshotData: data, key: profileSnapshot.header.id.keychainKey, iCloudSyncEnabled: iCloudSyncEnabled)
		}

		@Sendable func loadProfileHeaderList() throws -> ProfileSnapshot.HeaderList? {
			try keychainClient
				.getDataWithoutAuth(forKey: profileHeaderListKeychainKey)
				.map {
					try jsonDecoder().decode([ProfileSnapshot.Header].self, from: $0)
				}
				.flatMap(ProfileSnapshot.HeaderList.init)
		}

		@Sendable func saveProfileHeaderList(_ headers: ProfileSnapshot.HeaderList) throws {
			let data = try jsonEncoder().encode(headers)
			try keychainClient.setDataWithoutAuth(
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

		@Sendable func deleteProfileHeader(_ id: ProfileSnapshot.Header.ID) throws {
			if let profileHeaders = try loadProfileHeaderList() {
				let remainingHeaders = profileHeaders.filter { $0.id != id }
				if remainingHeaders.isEmpty {
					// Delete the list instea of keeping an empty list
					try deleteProfileHeaderList()
				} else {
					try saveProfileHeaderList(.init(remainingHeaders)!)
				}
			}
		}

		@Sendable func deleteProfileHeaderList() throws {
			try keychainClient.removeData(forKey: profileHeaderListKeychainKey)
		}

		@Sendable func deleteProfile(
			_ id: ProfileSnapshot.Header.ID
		) throws {
			try keychainClient.removeData(forKey: id.keychainKey)
			try deleteProfileHeader(id)
		}

		@Sendable func loadDeviceIdentifier() throws -> UUID? {
			let loaded = try keychainClient
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

		@Sendable func loadDeviceInfo() throws -> DeviceInfo? {
			let loaded = try keychainClient
				.getDataWithoutAuth(forKey: deviceInfoKey)
				.map {
					try jsonDecoder().decode(DeviceInfo.self, from: $0)
				}

			if let loaded {
				loggerGlobal.trace("Loaded deviceInfo: \(loaded)")
			} else {
				loggerGlobal.info("No deviceInfo loaded, was nil.")
			}
			return loaded
		}

		let deviceInfoAttributes = KeychainClient.AttributesWithoutAuth(
			iCloudSyncEnabled: false, // Never ever synced, since related to this device only..
			accessibility: .whenUnlocked,
			label: importantKeychainIdentifier("Radix Wallet device info"),
			comment: "Information about this device"
		)

		@Sendable func saveDeviceInfo(_ deviceInfo: DeviceInfo) throws {
			let data = try jsonEncoder().encode(deviceInfo)
			try keychainClient.setDataWithoutAuth(
				data,
				forKey: deviceInfoKey,
				attributes: deviceInfoAttributes
			)
			loggerGlobal.notice("Saved deviceInfo: \(deviceInfo)")
		}

		let loadProfileSnapshot: LoadProfileSnapshot = { id in
			guard
				let existingSnapshotData = try loadProfileSnapshotData(id)
			else {
				return nil
			}
			return try jsonDecoder().decode(ProfileSnapshot.self, from: existingSnapshotData)
		}

		return Self(
			saveProfileSnapshot: {
				profileSnapshot in
				let data = try jsonEncoder().encode(profileSnapshot)
				try saveProfile(
					snapshotData: data,
					key: profileSnapshot.header.id.keychainKey,
					iCloudSyncEnabled: profileSnapshot.appPreferences.security.isCloudProfileSyncEnabled
				)
			},
			loadProfileSnapshotData: loadProfileSnapshotData,
			loadProfileSnapshot: loadProfileSnapshot,
			loadProfile: { id in
				guard
					let existingSnapshot = try loadProfileSnapshot(id)
				else {
					return nil
				}
				return Profile(snapshot: existingSnapshot)
			},
			saveMnemonicForFactorSource: { privateFactorSource in
				let factorSource = privateFactorSource.factorSource
				let mnemonicWithPassphrase = privateFactorSource.mnemonicWithPassphrase
				let data = try jsonEncoder().encode(mnemonicWithPassphrase)
				let mostSecureAccesibilityAndAuthenticationPolicy = try queryMostSecureAccesibilityAndAuthenticationPolicy()
				let key = key(factorSourceID: factorSource.id)

				try keychainClient.setDataWithAuth(
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
			loadMnemonicByFactorSourceID: { factorSourceID, purpose, notifyIfMissing in
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
				guard let data = try keychainClient.getDataWithAuth(
					forKey: key,
					authenticationPrompt: authenticationPrompt
				) else {
					if notifyIfMissing {
						overlayWindowClient.scheduleAlertIgnoreAction(.missingMnemonicAlert)
					}
					return nil
				}
				return try jsonDecoder().decode(MnemonicWithPassphrase.self, from: data)
			},
			containsMnemonicIdentifiedByFactorSourceID: { factorSourceID in
				let key = key(factorSourceID: factorSourceID)
				return (try? keychainClient.contains(key)) ?? false
			},
			deleteMnemonicByFactorSourceID: deleteMnemonicByFactorSourceID,
			deleteProfileAndMnemonicsByFactorSourceIDs: {
				profileID,
					requestedToKeepInIcloud in
				guard
					let profileSnapshotData = try loadProfileSnapshotData(profileID)
				else {
					return
				}

				guard
					let profileSnapshot = try? jsonDecoder().decode(
						ProfileSnapshot.self,
						from: profileSnapshotData
					)
				else {
					return
				}

				// We want to keep the profile backup in iCloud.
				let isCloudSyncEnabled = profileSnapshot.appPreferences.security.isCloudProfileSyncEnabled

				let keepInICloudIfPresent = isCloudSyncEnabled && requestedToKeepInIcloud

				if !keepInICloudIfPresent {
					try deleteProfile(profileID)
				}

				for factorSourceID in profileSnapshot
					.factorSources
					.compactMap({ try? $0.extract(as: DeviceFactorSource.self) })
					.map(\.id)
				{
					loggerGlobal.debug("Deleting factor source with ID: \(factorSourceID)")
					try deleteMnemonicByFactorSourceID(factorSourceID)
				}

			},
			updateIsCloudProfileSyncEnabled: { profileId, change in
				guard
					let profileSnapshotData = try loadProfileSnapshotData(profileId),
					let headerList = try loadProfileHeaderList()
				else {
					return
				}

				switch change {
				case .disable:
					loggerGlobal.notice("Disabling iCloud sync of Profile snapshot (which should also delete it from iCloud)")
					try saveProfile(
						snapshotData: profileSnapshotData,
						key: profileId.keychainKey,
						iCloudSyncEnabled: false
					)
				case .enable:
					loggerGlobal.notice("Enabling iCloud sync of Profile snapshot")
					try saveProfile(
						snapshotData: profileSnapshotData,
						key: profileId.keychainKey,
						iCloudSyncEnabled: true
					)
				}
			},
			loadProfileHeaderList: loadProfileHeaderList,
			saveProfileHeaderList: saveProfileHeaderList,
			deleteProfileHeaderList: deleteProfileHeaderList,
			getDeviceInfoSetIfNil: { _ in
				fatalError()
			},
			loadDeviceInfo: loadDeviceInfo,
			saveDeviceInfo: saveDeviceInfo,
			deprecatedLoadDeviceID: {
				// See https://radixdlt.atlassian.net/l/cp/fmoH9KcN
				try keychainClient
					.getDataWithoutAuth(forKey: deviceIdentifierKey)
					.map {
						try jsonDecoder().decode(UUID.self, from: $0)
					}
			},
			deleteDeprecatedDeviceID: {
				// See https://radixdlt.atlassian.net/l/cp/fmoH9KcN
				try? keychainClient.removeData(forKey: deviceIdentifierKey)
			}
		)
	}()
}

let profileHeaderListKeychainKey: KeychainClient.Key = "profileHeaderList"
@available(*, deprecated, renamed: "deviceInfoKey", message: "Migrate to use `deviceInfoKey` instead")
private let deviceIdentifierKey: KeychainClient.Key = "deviceIdentifier"
private let deviceInfoKey: KeychainClient.Key = "deviceInfo"

extension ProfileSnapshot.Header.ID {
	private static let profileSnapshotKeychainKeyPrefix = "profileSnapshot"

	var keychainKey: KeychainClient.Key {
		"\(Self.profileSnapshotKeychainKeyPrefix) - \(uuidString)"
	}
}

private func key(factorSourceID: FactorSourceID.FromHash) -> KeychainClient.Key {
	.init(rawValue: .init(rawValue: factorSourceID.keychainKey)!)
}

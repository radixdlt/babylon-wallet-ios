import Sargon

// MARK: - KeychainAccess.Accessibility + @unchecked Sendable
extension KeychainAccess.Accessibility: @unchecked Sendable {}

// MARK: - KeychainAccess.AuthenticationPolicy + @unchecked Sendable
extension KeychainAccess.AuthenticationPolicy: @unchecked Sendable {}

// MARK: - SecureStorageError
enum SecureStorageError: Swift.Error, Equatable {
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
	typealias Value = SecureStorageClient

	static let liveValue: Self = {
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
			key: KeychainClient.Key
		) throws {
			try keychainClient.setDataWithoutAuth(
				data,
				forKey: key,
				attributes: .init(
					iCloudSyncEnabled: false,
					accessibility: .whenUnlocked, // do not delete the Profile if passcode gets deleted.
					label: importantKeychainIdentifier("Radix Wallet Data"),
					comment: "Contains your accounts, personas, authorizedDapps, linked connector extensions and wallet app preferences."
				)
			)
		}

		@Sendable func loadProfileHeaderList() throws -> Profile.HeaderList? {
			try keychainClient
				.getDataWithoutAuth(forKey: profileHeaderListKeychainKey)
				.map {
					try jsonDecoder().decode([Throwable<Profile.Header>].self, from: $0)
				}
				.flatMap {
					.init($0.compactMap { try? $0.result.get() })
				}
		}

		@Sendable func saveProfileHeaderList(_ headers: Profile.HeaderList) throws {
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

		@Sendable func deleteProfileHeader(_ id: ProfileID) throws {
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
			_ id: ProfileID
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

		@Sendable func deleteDeviceInfo() throws {
			try keychainClient.removeData(forKey: deviceInfoKey)
		}

		@Sendable func loadMnemonicFor(
			key: KeychainClient.Key,
			notifyIfMissing: Bool
		) throws -> MnemonicWithPassphrase? {
			let authenticationPrompt: KeychainClient.AuthenticationPrompt = NonEmptyString(rawValue: L10n.Biometrics.Prompt.title).map { KeychainClient.AuthenticationPrompt($0) } ?? "Authenticate to continue."
			guard let data = try keychainClient.getDataWithAuth(
				forKey: key,
				authenticationPrompt: authenticationPrompt
			) else {
				if notifyIfMissing {
					overlayWindowClient.scheduleAlertAndIgnoreAction(.missingMnemonicAlert)
				}
				return nil
			}
			return try jsonDecoder().decode(MnemonicWithPassphrase.self, from: data)
		}

		let loadMnemonicByFactorSourceID: LoadMnemonicByFactorSourceID = { request in
			let key = key(factorSourceID: request.factorSourceID)
			return try loadMnemonicFor(key: key, notifyIfMissing: request.notifyIfMissing)
		}

		let saveMnemonicForFactorSource: SaveMnemonicForFactorSource = { privateFactorSource in
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
					label: importantKeychainIdentifier("Radix Wallet Factor Secret")!,
					comment: .init("Created on \(factorSource.hint.name) \(factorSource.supportsOlympia ? " (Olympia)" : "")")
				)
			)
		}

		let saveRadixConnectMobileSession: SaveRadixConnectMobileSession = { sessionId, encodedSession in
			let mostSecureAccesibilityAndAuthenticationPolicy = try queryMostSecureAccesibilityAndAuthenticationPolicy()

			try keychainClient.setDataWithoutAuth(
				encodedSession,
				forKey: .init(.init(rawValue: sessionId.uuidString)!),
				attributes: .init(
					iCloudSyncEnabled: false,
					accessibility: mostSecureAccesibilityAndAuthenticationPolicy.accessibility,
					label: importantKeychainIdentifier("Radix Wallet Mobile2Mobile session secret")!,
					comment: .init("Created for \(sessionId)")
				)
			)
		}

		let loadRadixConnectMobileSession: LoadRadixConnectMobileSession = { id in
			try keychainClient.getDataWithoutAuth(forKey: .init(.init(rawValue: id.uuidString)!))
		}

		#if DEBUG
		let getAllMnemonics: GetAllMnemonics = {
			let unfilteredKeys = keychainClient.getAllKeysMatchingAttributes(
				synchronizable: false,
				accessibility: .whenPasscodeSetThisDeviceOnly
			)

			let keys = unfilteredKeys.filter { $0.rawValue.rawValue.starts(with: "\(FactorSourceKind.device.rawValue):") }

			return keys.compactMap {
				guard
					let factorSourceID = FactorSourceIDFromHash(keychainKey: $0),
					let mnemonicWithPassphrase = try? loadMnemonicByFactorSourceID(
						.init(factorSourceID: factorSourceID, notifyIfMissing: false)
					)
				else {
					return nil
				}
				return KeyedMnemonicWithPassphrase(
					factorSourceID: factorSourceID,
					mnemonicWithPassphrase: mnemonicWithPassphrase
				)
			}
		}
		#endif

		let saveProfileSnapshotData: SaveProfileSnapshotData = { id, data in
			try saveProfile(snapshotData: data, key: id.keychainKey)
		}

		let loadMnemonicDataByFactorSourceID: LoadMnemonicDataByFactorSourceID = { request in
			let key = key(factorSourceID: request.factorSourceID)

			let authenticationPrompt: KeychainClient.AuthenticationPrompt = NonEmptyString(rawValue: L10n.Biometrics.Prompt.title).map { KeychainClient.AuthenticationPrompt($0) } ?? "Authenticate to continue."
			guard let data = try keychainClient.getDataWithAuth(
				forKey: key,
				authenticationPrompt: authenticationPrompt
			) else {
				return nil
			}

			return data
		}

		let saveMnemonicForFactorSourceData: SaveMnemonicForFactorSourceData = { id, data in
			let mostSecureAccesibilityAndAuthenticationPolicy = try queryMostSecureAccesibilityAndAuthenticationPolicy()
			let key = key(factorSourceID: id)

			try keychainClient.setDataWithAuth(
				data,
				forKey: key,
				attributes: .init(
					iCloudSyncEnabled: false,
					accessibility: mostSecureAccesibilityAndAuthenticationPolicy.accessibility,
					authenticationPolicy: mostSecureAccesibilityAndAuthenticationPolicy.authenticationPolicy,
					label: importantKeychainIdentifier("Radix Wallet Factor Secret")!,
					comment: .init("mnemonic")
				)
			)
		}

		let containsMnemonicIdentifiedByFactorSourceID: ContainsMnemonicIdentifiedByFactorSourceID = { factorSourceID in
			let key = key(factorSourceID: factorSourceID)
			return (try? keychainClient.contains(key)) ?? false
		}

		let deleteProfileAndMnemonicsByFactorSourceIDs: DeleteProfileAndMnemonicsByFactorSourceIDs = {
			profileID,
				requestedToKeepInIcloud in
			guard
				let profileSnapshotData = try loadProfileSnapshotData(profileID)
			else {
				return
			}

			guard
				let profileSnapshot = try? Profile(jsonData: profileSnapshotData)
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
		}

		let disableCloudProfileSync: DisableCloudProfileSync = { profileId in
			guard let profileSnapshotData = try loadProfileSnapshotData(profileId) else { return }

			loggerGlobal.notice("Disabling iCloud sync of Profile snapshot (which should also delete it from iCloud)")
			try saveProfile(
				snapshotData: profileSnapshotData,
				key: profileId.keychainKey
			)
		}

		let deprecatedLoadDeviceID: DeprecatedLoadDeviceID = {
			// See https://radixdlt.atlassian.net/l/cp/fmoH9KcN
			try keychainClient
				.getDataWithoutAuth(forKey: deviceIdentifierKey)
				.map {
					try jsonDecoder().decode(UUID.self, from: $0)
				}
		}

		let deleteDeprecatedDeviceID: DeleteDeprecatedDeviceID = {
			// See https://radixdlt.atlassian.net/l/cp/fmoH9KcN
			try? keychainClient.removeData(forKey: deviceIdentifierKey)
		}

		@Sendable func loadP2PLinks() throws -> P2PLinks? {
			let loaded = try keychainClient
				.getDataWithoutAuth(forKey: p2pLinksKey)
				.map {
					try jsonDecoder().decode(P2PLinks.self, from: $0)
				}

			if let loaded {
				loggerGlobal.trace("Loaded loadP2PLinks: \(loaded)")
			} else {
				loggerGlobal.info("No loadP2PLinks loaded, was nil.")
			}
			return loaded
		}

		let p2pLinksAttributes = KeychainClient.AttributesWithoutAuth(
			iCloudSyncEnabled: false,
			accessibility: .whenUnlocked,
			label: importantKeychainIdentifier("Radix Wallet P2P Links"),
			comment: "Contains linked connector extensions"
		)

		@Sendable func saveP2PLinks(_ p2pLinks: P2PLinks) throws {
			let data = try jsonEncoder().encode(p2pLinks)
			try keychainClient.setDataWithoutAuth(
				data,
				forKey: p2pLinksKey,
				attributes: p2pLinksAttributes
			)
			loggerGlobal.notice("Saved p2pLinks: \(p2pLinks)")
		}

		@Sendable func loadP2PLinksPrivateKey() throws -> Curve25519.PrivateKey? {
			try keychainClient
				.getDataWithoutAuth(forKey: p2pLinksPrivateKey)
				.map {
					try Curve25519.PrivateKey(rawRepresentation: $0)
				}
		}

		let p2pLinksPrivateKeyAttributes = KeychainClient.AttributesWithoutAuth(
			iCloudSyncEnabled: false,
			accessibility: .whenUnlocked,
			label: importantKeychainIdentifier("Radix Wallet Private Key Per P2P link"),
			comment: "Contains a wallet private key for a specific P2P link"
		)

		@Sendable func saveP2PLinksPrivateKey(privateKey: Curve25519.PrivateKey) throws {
			try keychainClient.setDataWithoutAuth(
				privateKey.rawRepresentation,
				forKey: p2pLinksPrivateKey,
				attributes: p2pLinksPrivateKeyAttributes
			)
			loggerGlobal.notice("Saved p2pLinksPrivateKeyKey")
		}

		let keychainChanged = keychainClient.keychainChanged

		#if DEBUG
		return Self(
			loadProfileSnapshotData: loadProfileSnapshotData,
			saveProfileSnapshotData: saveProfileSnapshotData,
			saveMnemonicForFactorSource: saveMnemonicForFactorSource,
			loadMnemonicByFactorSourceID: loadMnemonicByFactorSourceID,
			containsMnemonicIdentifiedByFactorSourceID: containsMnemonicIdentifiedByFactorSourceID,
			deleteMnemonicByFactorSourceID: deleteMnemonicByFactorSourceID,
			deleteProfileAndMnemonicsByFactorSourceIDs: deleteProfileAndMnemonicsByFactorSourceIDs,
			disableCloudProfileSync: disableCloudProfileSync,
			loadProfileHeaderList: loadProfileHeaderList,
			saveProfileHeaderList: saveProfileHeaderList,
			deleteProfileHeaderList: deleteProfileHeaderList,
			loadDeviceInfo: loadDeviceInfo,
			saveDeviceInfo: saveDeviceInfo,
			deleteDeviceInfo: deleteDeviceInfo,
			deprecatedLoadDeviceID: deprecatedLoadDeviceID,
			deleteDeprecatedDeviceID: deleteDeprecatedDeviceID,
			saveRadixConnectMobileSession: saveRadixConnectMobileSession,
			loadRadixConnectMobileSession: loadRadixConnectMobileSession,
			loadP2PLinks: loadP2PLinks,
			saveP2PLinks: saveP2PLinks,
			loadP2PLinksPrivateKey: loadP2PLinksPrivateKey,
			saveP2PLinksPrivateKey: saveP2PLinksPrivateKey,
			keychainChanged: keychainChanged,
			getAllMnemonics: getAllMnemonics,
			loadMnemonicDataByFactorSourceID: loadMnemonicDataByFactorSourceID,
			saveMnemonicForFactorSourceData: saveMnemonicForFactorSourceData
		)
		#else
		return Self(
			loadProfileSnapshotData: loadProfileSnapshotData,
			saveProfileSnapshotData: saveProfileSnapshotData,
			saveMnemonicForFactorSource: saveMnemonicForFactorSource,
			loadMnemonicByFactorSourceID: loadMnemonicByFactorSourceID,
			containsMnemonicIdentifiedByFactorSourceID: containsMnemonicIdentifiedByFactorSourceID,
			deleteMnemonicByFactorSourceID: deleteMnemonicByFactorSourceID,
			deleteProfileAndMnemonicsByFactorSourceIDs: deleteProfileAndMnemonicsByFactorSourceIDs,
			disableCloudProfileSync: disableCloudProfileSync,
			loadProfileHeaderList: loadProfileHeaderList,
			saveProfileHeaderList: saveProfileHeaderList,
			deleteProfileHeaderList: deleteProfileHeaderList,
			loadDeviceInfo: loadDeviceInfo,
			saveDeviceInfo: saveDeviceInfo,
			deleteDeviceInfo: deleteDeviceInfo,
			deprecatedLoadDeviceID: deprecatedLoadDeviceID,
			deleteDeprecatedDeviceID: deleteDeprecatedDeviceID,
			saveRadixConnectMobileSession: saveRadixConnectMobileSession,
			loadRadixConnectMobileSession: loadRadixConnectMobileSession,
			loadP2PLinks: loadP2PLinks,
			saveP2PLinks: saveP2PLinks,
			loadP2PLinksPrivateKey: loadP2PLinksPrivateKey,
			saveP2PLinksPrivateKey: saveP2PLinksPrivateKey,
			keychainChanged: keychainChanged,
			loadMnemonicDataByFactorSourceID: loadMnemonicDataByFactorSourceID,
			saveMnemonicForFactorSourceData: saveMnemonicForFactorSourceData
		)
		#endif
	}()
}

let profileHeaderListKeychainKey: KeychainClient.Key = "profileHeaderList"
@available(*, deprecated, renamed: "deviceInfoKey", message: "Migrate to use `deviceInfoKey` instead")
private let deviceIdentifierKey: KeychainClient.Key = "deviceIdentifier"
private let deviceInfoKey: KeychainClient.Key = "deviceInfo"
private let p2pLinksKey: KeychainClient.Key = "p2pLinks"
private let p2pLinksPrivateKey: KeychainClient.Key = "p2pLinksPrivateKey"

extension ProfileID {
	private static let profileSnapshotKeychainKeyPrefix = "profileSnapshot"

	var keychainKey: KeychainClient.Key {
		"\(Self.profileSnapshotKeychainKeyPrefix) - \(uuidString)"
	}
}

private func key(factorSourceID: FactorSourceIDFromHash) -> KeychainClient.Key {
	.init(rawValue: .init(rawValue: factorSourceID.keychainKey)!)
}

extension OverlayWindowClient.Item.AlertState {
	fileprivate static let missingMnemonicAlert = Self(
		title: { TextState(L10n.Common.NoMnemonicAlert.title) },
		message: { TextState(L10n.Common.NoMnemonicAlert.text) }
	)
}

extension FactorSourceIDFromHash {
	init?(keychainKey: KeychainClient.Key) {
		let key = keychainKey.rawValue.rawValue
		guard
			case let parts = key.split(separator: Self.keychainKeySeparator),
			parts.count == 2,
			let kind = FactorSourceKind(rawValue: String(parts[0])),
			case let hex32 = String(parts[1]),
			let exactly32Bytes = try? Exactly32Bytes(hex: hex32)
		else {
			return nil
		}
		self.init(kind: kind, body: exactly32Bytes)
	}
}

extension FactorSourceIdFromHash {
	static let keychainKeySeparator = ":"
	/// NEVER EVER CHANGE THIS! If you do, users apps will be unable to load the Mnemonic
	/// from keychain!
	var keychainKey: String {
		"\(kind)\(Self.keychainKeySeparator)\(body.data.hex())"
	}
}

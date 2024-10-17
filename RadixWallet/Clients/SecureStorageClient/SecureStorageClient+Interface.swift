import Sargon

extension Profile {
	typealias Header = Sargon.Header
	typealias HeaderList = NonEmpty<IdentifiedArrayOf<Header>>
}

// MARK: - SecureStorageClient
struct SecureStorageClient: Sendable {
	var loadProfileSnapshotData: LoadProfileSnapshotData
	var saveProfileSnapshotData: SaveProfileSnapshotData

	var saveMnemonicForFactorSource: SaveMnemonicForFactorSource
	var loadMnemonicByFactorSourceID: LoadMnemonicByFactorSourceID
	var containsMnemonicIdentifiedByFactorSourceID: ContainsMnemonicIdentifiedByFactorSourceID

	var deleteMnemonicByFactorSourceID: DeleteMnemonicByFactorSourceID
	var deleteProfileAndMnemonicsByFactorSourceIDs: DeleteProfileAndMnemonicsByFactorSourceIDs

	var disableCloudProfileSync: DisableCloudProfileSync

	var loadProfileHeaderList: LoadProfileHeaderList
	var saveProfileHeaderList: SaveProfileHeaderList
	var deleteProfileHeaderList: DeleteProfileHeaderList

	var loadDeviceInfo: LoadDeviceInfo
	var saveDeviceInfo: SaveDeviceInfo
	var deleteDeviceInfo: DeleteDeviceInfo

	/// See https://radixdlt.atlassian.net/l/cp/fmoH9KcN
	var deprecatedLoadDeviceID: DeprecatedLoadDeviceID
	/// See https://radixdlt.atlassian.net/l/cp/fmoH9KcN
	var deleteDeprecatedDeviceID: DeleteDeprecatedDeviceID

	var saveRadixConnectMobileSession: SaveRadixConnectMobileSession
	var loadRadixConnectMobileSession: LoadRadixConnectMobileSession

	var loadP2PLinks: LoadP2PLinks
	var saveP2PLinks: SaveP2PLinks

	var loadP2PLinksPrivateKey: LoadP2PLinksPrivateKey
	var saveP2PLinksPrivateKey: SaveP2PLinksPrivateKey
	var keychainChanged: KeychainChanged

	var loadMnemonicDataByFactorSourceID: LoadMnemonicDataByFactorSourceID
	var saveMnemonicForFactorSourceData: SaveMnemonicForFactorSourceData

	#if DEBUG
	var getAllMnemonics: GetAllMnemonics
	#endif

	#if DEBUG
	init(
		loadProfileSnapshotData: @escaping LoadProfileSnapshotData,
		saveProfileSnapshotData: @escaping SaveProfileSnapshotData,
		saveMnemonicForFactorSource: @escaping SaveMnemonicForFactorSource,
		loadMnemonicByFactorSourceID: @escaping LoadMnemonicByFactorSourceID,
		containsMnemonicIdentifiedByFactorSourceID: @escaping ContainsMnemonicIdentifiedByFactorSourceID,
		deleteMnemonicByFactorSourceID: @escaping DeleteMnemonicByFactorSourceID,
		deleteProfileAndMnemonicsByFactorSourceIDs: @escaping DeleteProfileAndMnemonicsByFactorSourceIDs,
		disableCloudProfileSync: @escaping DisableCloudProfileSync,
		loadProfileHeaderList: @escaping LoadProfileHeaderList,
		saveProfileHeaderList: @escaping SaveProfileHeaderList,
		deleteProfileHeaderList: @escaping DeleteProfileHeaderList,
		loadDeviceInfo: @escaping LoadDeviceInfo,
		saveDeviceInfo: @escaping SaveDeviceInfo,
		deleteDeviceInfo: @escaping DeleteDeviceInfo,
		deprecatedLoadDeviceID: @escaping DeprecatedLoadDeviceID,
		deleteDeprecatedDeviceID: @escaping DeleteDeprecatedDeviceID,
		saveRadixConnectMobileSession: @escaping SaveRadixConnectMobileSession,
		loadRadixConnectMobileSession: @escaping LoadRadixConnectMobileSession,
		loadP2PLinks: @escaping LoadP2PLinks,
		saveP2PLinks: @escaping SaveP2PLinks,
		loadP2PLinksPrivateKey: @escaping LoadP2PLinksPrivateKey,
		saveP2PLinksPrivateKey: @escaping SaveP2PLinksPrivateKey,
		keychainChanged: @escaping KeychainChanged,
		getAllMnemonics: @escaping GetAllMnemonics,
		loadMnemonicDataByFactorSourceID: @escaping LoadMnemonicDataByFactorSourceID,
		saveMnemonicForFactorSourceData: @escaping SaveMnemonicForFactorSourceData
	) {
		self.loadProfileSnapshotData = loadProfileSnapshotData
		self.saveProfileSnapshotData = saveProfileSnapshotData
		self.saveMnemonicForFactorSource = saveMnemonicForFactorSource
		self.loadMnemonicByFactorSourceID = loadMnemonicByFactorSourceID
		self.containsMnemonicIdentifiedByFactorSourceID = containsMnemonicIdentifiedByFactorSourceID
		self.deleteMnemonicByFactorSourceID = deleteMnemonicByFactorSourceID
		self.deleteProfileAndMnemonicsByFactorSourceIDs = deleteProfileAndMnemonicsByFactorSourceIDs
		self.disableCloudProfileSync = disableCloudProfileSync
		self.loadProfileHeaderList = loadProfileHeaderList
		self.saveProfileHeaderList = saveProfileHeaderList
		self.deleteProfileHeaderList = deleteProfileHeaderList
		self.loadDeviceInfo = loadDeviceInfo
		self.saveDeviceInfo = saveDeviceInfo
		self.deleteDeviceInfo = deleteDeviceInfo
		self.deprecatedLoadDeviceID = deprecatedLoadDeviceID
		self.deleteDeprecatedDeviceID = deleteDeprecatedDeviceID
		self.loadP2PLinks = loadP2PLinks
		self.saveP2PLinks = saveP2PLinks
		self.loadP2PLinksPrivateKey = loadP2PLinksPrivateKey
		self.saveP2PLinksPrivateKey = saveP2PLinksPrivateKey
		self.getAllMnemonics = getAllMnemonics
		self.saveRadixConnectMobileSession = saveRadixConnectMobileSession
		self.loadRadixConnectMobileSession = loadRadixConnectMobileSession
		self.keychainChanged = keychainChanged
		self.loadMnemonicDataByFactorSourceID = loadMnemonicDataByFactorSourceID
		self.saveMnemonicForFactorSourceData = saveMnemonicForFactorSourceData
	}
	#else

	init(
		loadProfileSnapshotData: @escaping LoadProfileSnapshotData,
		saveProfileSnapshotData: @escaping SaveProfileSnapshotData,
		saveMnemonicForFactorSource: @escaping SaveMnemonicForFactorSource,
		loadMnemonicByFactorSourceID: @escaping LoadMnemonicByFactorSourceID,
		containsMnemonicIdentifiedByFactorSourceID: @escaping ContainsMnemonicIdentifiedByFactorSourceID,
		deleteMnemonicByFactorSourceID: @escaping DeleteMnemonicByFactorSourceID,
		deleteProfileAndMnemonicsByFactorSourceIDs: @escaping DeleteProfileAndMnemonicsByFactorSourceIDs,
		disableCloudProfileSync: @escaping DisableCloudProfileSync,
		loadProfileHeaderList: @escaping LoadProfileHeaderList,
		saveProfileHeaderList: @escaping SaveProfileHeaderList,
		deleteProfileHeaderList: @escaping DeleteProfileHeaderList,
		loadDeviceInfo: @escaping LoadDeviceInfo,
		saveDeviceInfo: @escaping SaveDeviceInfo,
		deleteDeviceInfo: @escaping DeleteDeviceInfo,
		deprecatedLoadDeviceID: @escaping DeprecatedLoadDeviceID,
		deleteDeprecatedDeviceID: @escaping DeleteDeprecatedDeviceID,
		saveRadixConnectMobileSession: @escaping SaveRadixConnectMobileSession,
		loadRadixConnectMobileSession: @escaping LoadRadixConnectMobileSession,
		loadP2PLinks: @escaping LoadP2PLinks,
		saveP2PLinks: @escaping SaveP2PLinks,
		loadP2PLinksPrivateKey: @escaping LoadP2PLinksPrivateKey,
		saveP2PLinksPrivateKey: @escaping SaveP2PLinksPrivateKey,
		keychainChanged: @escaping KeychainChanged,

		loadMnemonicByFactorSourceID: @escaping LoadMnemonicByFactorSourceID,
		saveMnemonicForFactorSourceData: @escaping SaveMnemonicForFactorSourceData
	) {
		self.loadProfileSnapshotData = loadProfileSnapshotData
		self.saveProfileSnapshotData = saveProfileSnapshotData
		self.saveMnemonicForFactorSource = saveMnemonicForFactorSource
		self.loadMnemonicByFactorSourceID = loadMnemonicByFactorSourceID
		self.containsMnemonicIdentifiedByFactorSourceID = containsMnemonicIdentifiedByFactorSourceID
		self.deleteMnemonicByFactorSourceID = deleteMnemonicByFactorSourceID
		self.deleteProfileAndMnemonicsByFactorSourceIDs = deleteProfileAndMnemonicsByFactorSourceIDs
		self.disableCloudProfileSync = disableCloudProfileSync
		self.loadProfileHeaderList = loadProfileHeaderList
		self.saveProfileHeaderList = saveProfileHeaderList
		self.deleteProfileHeaderList = deleteProfileHeaderList
		self.loadDeviceInfo = loadDeviceInfo
		self.saveDeviceInfo = saveDeviceInfo
		self.deleteDeviceInfo = deleteDeviceInfo
		self.deprecatedLoadDeviceID = deprecatedLoadDeviceID
		self.deleteDeprecatedDeviceID = deleteDeprecatedDeviceID
		self.saveRadixConnectMobileSession = saveRadixConnectMobileSession
		self.loadRadixConnectMobileSession = loadRadixConnectMobileSession
		self.loadP2PLinks = loadP2PLinks
		self.saveP2PLinks = saveP2PLinks
		self.loadP2PLinksPrivateKey = loadP2PLinksPrivateKey
		self.saveP2PLinksPrivateKey = saveP2PLinksPrivateKey
		self.keychainChanged = keychainChanged
		self.loadMnemonicDataByFactorSourceID = loadMnemonicDataByFactorSourceID
		self.saveMnemonicForFactorSourceData = saveMnemonicForFactorSourceData
	}
	#endif // DEBUG
}

// MARK: - LoadMnemonicByFactorSourceIDRequest
struct LoadMnemonicByFactorSourceIDRequest: Sendable, Hashable {
	let factorSourceID: FactorSourceIDFromHash
	let notifyIfMissing: Bool
}

extension SecureStorageClient {
	typealias DisableCloudProfileSync = @Sendable (ProfileID) throws -> Void
	typealias SaveProfileSnapshotData = @Sendable (ProfileID, Data) throws -> Void
	typealias LoadProfileSnapshotData = @Sendable (ProfileID) throws -> Data?
	typealias DeleteProfile = @Sendable (ProfileID) throws -> Void

	typealias SaveMnemonicForFactorSource = @Sendable (PrivateHierarchicalDeterministicFactorSource) throws -> Void
	typealias LoadMnemonicByFactorSourceID = @Sendable (LoadMnemonicByFactorSourceIDRequest) throws -> MnemonicWithPassphrase?
	typealias SaveMnemonicForFactorSourceData = @Sendable (FactorSourceIDFromHash, Data) throws -> Void
	typealias LoadMnemonicDataByFactorSourceID = @Sendable (LoadMnemonicByFactorSourceIDRequest) throws -> Data?
	typealias ContainsMnemonicIdentifiedByFactorSourceID = @Sendable (FactorSourceIDFromHash) -> Bool

	#if DEBUG
	typealias GetAllMnemonics = @Sendable () -> [KeyedMnemonicWithPassphrase]
	#endif

	typealias DeleteMnemonicByFactorSourceID = @Sendable (FactorSourceIDFromHash) throws -> Void
	typealias DeleteProfileAndMnemonicsByFactorSourceIDs = @Sendable (ProfileID, _ keepInICloudIfPresent: Bool) throws -> Void

	typealias LoadProfileHeaderList = @Sendable () throws -> Profile.HeaderList?
	typealias SaveProfileHeaderList = @Sendable (Profile.HeaderList) throws -> Void
	typealias DeleteProfileHeaderList = @Sendable () throws -> Void

	typealias LoadDeviceInfo = @Sendable () throws -> DeviceInfo?
	typealias SaveDeviceInfo = @Sendable (DeviceInfo) throws -> Void
	typealias DeleteDeviceInfo = @Sendable () throws -> Void

	typealias SaveRadixConnectMobileSession = @Sendable (SessionId, BagOfBytes) throws -> Void
	typealias LoadRadixConnectMobileSession = @Sendable (SessionId) throws -> BagOfBytes?

	/// See https://radixdlt.atlassian.net/l/cp/fmoH9KcN
	typealias DeprecatedLoadDeviceID = @Sendable () throws -> DeviceID?
	/// See https://radixdlt.atlassian.net/l/cp/fmoH9KcN
	typealias DeleteDeprecatedDeviceID = @Sendable () -> Void

	typealias LoadP2PLinks = @Sendable () throws -> P2PLinks?
	typealias SaveP2PLinks = @Sendable (P2PLinks) throws -> Void

	typealias LoadP2PLinksPrivateKey = @Sendable () throws -> Curve25519.PrivateKey?
	typealias SaveP2PLinksPrivateKey = @Sendable (Curve25519.PrivateKey) throws -> Void

	typealias KeychainChanged = @Sendable () -> AnyAsyncSequence<Void>

	enum LoadMnemonicPurpose: Sendable, Hashable, CustomStringConvertible {
		case signTransaction
		case signAuthChallenge
		case importOlympiaAccounts

		case accountRecoveryScan

		case displaySeedPhrase
		case createEntity(kind: EntityKind)

		/// Check if account(/persona) recovery is needed
		case checkingAccounts

		case createSignAuthKey(forEntityKind: EntityKind)

		case updateAccountMetadata

		var description: String {
			switch self {
			case .accountRecoveryScan:
				"accountRecoveryScan"
			case .importOlympiaAccounts:
				"importOlympiaAccounts"
			case .displaySeedPhrase:
				"displaySeedPhrase"
			case let .createEntity(kind):
				"createEntity.\(kind)"
			case .signAuthChallenge:
				"signAuthChallenge"
			case .signTransaction:
				"signTransaction"
			case .checkingAccounts:
				"checkingAccounts"
			case let .createSignAuthKey(kind):
				"createSignAuthKey.\(kind)"
			case .updateAccountMetadata:
				"updateAccountMetadata"
			}
		}
	}
}

extension SecureStorageClient {
	@Sendable
	func loadMnemonic(
		factorSourceID: FactorSourceIDFromHash,
		notifyIfMissing: Bool = true
	) throws -> MnemonicWithPassphrase? {
		try self.loadMnemonicByFactorSourceID(.init(factorSourceID: factorSourceID, notifyIfMissing: notifyIfMissing))
	}

	@Sendable
	func deleteProfileAndMnemonicsByFactorSourceIDs(profileID: Profile.ID, keepInICloudIfPresent: Bool) throws {
		try deleteProfileAndMnemonicsByFactorSourceIDs(profileID, keepInICloudIfPresent)
	}
}

extension DeviceInfo {
	init(id: UUID, date: Date = .now, description: String? = nil) {
		self.init(
			id: id,
			date: date,
			description: description ?? "iPhone",
			systemVersion: nil,
			hostAppVersion: nil,
			hostVendor: "Apple"
		)
	}
}

#if DEBUG

// MARK: - KeyedMnemonicWithPassphrase
struct KeyedMnemonicWithPassphrase: Sendable, Hashable {
	let factorSourceID: FactorSourceIDFromHash
	let mnemonicWithPassphrase: MnemonicWithPassphrase
}
#endif

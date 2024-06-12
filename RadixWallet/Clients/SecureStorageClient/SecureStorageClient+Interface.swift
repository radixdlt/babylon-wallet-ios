import Sargon

extension Profile {
	public typealias Header = Sargon.Header
	public typealias HeaderList = NonEmpty<IdentifiedArrayOf<Header>>
}

// MARK: - SecureStorageClient
public struct SecureStorageClient: Sendable {
	public var saveProfileSnapshot: SaveProfileSnapshot
	public var loadProfileSnapshotData: LoadProfileSnapshotData
	public var loadProfileSnapshot: LoadProfileSnapshot
	public var loadProfile: LoadProfile
	public var deleteProfile: DeleteProfile

	public var saveMnemonicForFactorSource: SaveMnemonicForFactorSource
	public var loadMnemonicByFactorSourceID: LoadMnemonicByFactorSourceID
	public var containsMnemonicIdentifiedByFactorSourceID: ContainsMnemonicIdentifiedByFactorSourceID

	public var deleteMnemonicByFactorSourceID: DeleteMnemonicByFactorSourceID
	public var deleteProfileAndMnemonicsByFactorSourceIDs: DeleteProfileAndMnemonicsByFactorSourceIDs

	public var disableCloudProfileSync: DisableCloudProfileSync

	public var loadProfileHeaderList: LoadProfileHeaderList
	public var saveProfileHeaderList: SaveProfileHeaderList
	public var deleteProfileHeaderList: DeleteProfileHeaderList

	public var loadDeviceInfo: LoadDeviceInfo
	public var saveDeviceInfo: SaveDeviceInfo

	/// See https://radixdlt.atlassian.net/l/cp/fmoH9KcN
	public var deprecatedLoadDeviceID: DeprecatedLoadDeviceID
	/// See https://radixdlt.atlassian.net/l/cp/fmoH9KcN
	public var deleteDeprecatedDeviceID: DeleteDeprecatedDeviceID

	public var saveRadixConnectRelaySession: SaveRadixConnectRelaySession
	public var loadRadixConnectRelaySession: LoadRadixConnectRelaySession

	public var loadP2PLinks: LoadP2PLinks
	public var saveP2PLinks: SaveP2PLinks

	public var loadP2PLinksPrivateKey: LoadP2PLinksPrivateKey
	public var saveP2PLinksPrivateKey: SaveP2PLinksPrivateKey
	public var keychainChanged: KeychainChanged

	#if DEBUG
	public var getAllMnemonics: GetAllMnemonics
	#endif

	#if DEBUG
	init(
		saveProfileSnapshot: @escaping SaveProfileSnapshot,
		loadProfileSnapshotData: @escaping LoadProfileSnapshotData,
		loadProfileSnapshot: @escaping LoadProfileSnapshot,
		loadProfile: @escaping LoadProfile,
		deleteProfile: @escaping DeleteProfile,
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
		deprecatedLoadDeviceID: @escaping DeprecatedLoadDeviceID,
		deleteDeprecatedDeviceID: @escaping DeleteDeprecatedDeviceID,
		saveRadixConnectRelaySession: @escaping SaveRadixConnectRelaySession,
		loadRadixConnectRelaySession: @escaping LoadRadixConnectRelaySession,
		loadP2PLinks: @escaping LoadP2PLinks,
		saveP2PLinks: @escaping SaveP2PLinks,
		loadP2PLinksPrivateKey: @escaping LoadP2PLinksPrivateKey,
		saveP2PLinksPrivateKey: @escaping SaveP2PLinksPrivateKey,
		keychainChanged: @escaping KeychainChanged,
		getAllMnemonics: @escaping GetAllMnemonics
	) {
		self.saveProfileSnapshot = saveProfileSnapshot
		self.loadProfileSnapshotData = loadProfileSnapshotData
		self.loadProfileSnapshot = loadProfileSnapshot
		self.loadProfile = loadProfile
		self.deleteProfile = deleteProfile
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
		self.deprecatedLoadDeviceID = deprecatedLoadDeviceID
		self.deleteDeprecatedDeviceID = deleteDeprecatedDeviceID
		self.loadP2PLinks = loadP2PLinks
		self.saveP2PLinks = saveP2PLinks
		self.loadP2PLinksPrivateKey = loadP2PLinksPrivateKey
		self.saveP2PLinksPrivateKey = saveP2PLinksPrivateKey
		self.getAllMnemonics = getAllMnemonics
		self.saveRadixConnectRelaySession = saveRadixConnectRelaySession
		self.loadRadixConnectRelaySession = loadRadixConnectRelaySession
		self.keychainChanged = keychainChanged
	}
	#else

	init(
		saveProfileSnapshot: @escaping SaveProfileSnapshot,
		loadProfileSnapshotData: @escaping LoadProfileSnapshotData,
		loadProfileSnapshot: @escaping LoadProfileSnapshot,
		loadProfile: @escaping LoadProfile,
		deleteProfile: @escaping DeleteProfile,
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
		deprecatedLoadDeviceID: @escaping DeprecatedLoadDeviceID,
		deleteDeprecatedDeviceID: @escaping DeleteDeprecatedDeviceID,
		saveRadixConnectRelaySession: @escaping SaveRadixConnectRelaySession,
		loadRadixConnectRelaySession: @escaping LoadRadixConnectRelaySession,
		loadP2PLinks: @escaping LoadP2PLinks,
		saveP2PLinks: @escaping SaveP2PLinks,
		loadP2PLinksPrivateKey: @escaping LoadP2PLinksPrivateKey,
		saveP2PLinksPrivateKey: @escaping SaveP2PLinksPrivateKey,
		keychainChanged: @escaping KeychainChanged
	) {
		self.saveProfileSnapshot = saveProfileSnapshot
		self.loadProfileSnapshotData = loadProfileSnapshotData
		self.loadProfileSnapshot = loadProfileSnapshot
		self.loadProfile = loadProfile
		self.deleteProfile = deleteProfile
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
		self.deprecatedLoadDeviceID = deprecatedLoadDeviceID
		self.deleteDeprecatedDeviceID = deleteDeprecatedDeviceID
		self.saveRadixConnectRelaySession = saveRadixConnectRelaySession
		self.loadRadixConnectRelaySession = loadRadixConnectRelaySession
		self.loadP2PLinks = loadP2PLinks
		self.saveP2PLinks = saveP2PLinks
		self.loadP2PLinksPrivateKey = loadP2PLinksPrivateKey
		self.saveP2PLinksPrivateKey = saveP2PLinksPrivateKey
		self.keychainChanged = keychainChanged
	}
	#endif // DEBUG
}

// MARK: - LoadMnemonicByFactorSourceIDRequest
public struct LoadMnemonicByFactorSourceIDRequest: Sendable, Hashable {
	public let factorSourceID: FactorSourceIDFromHash
	public let notifyIfMissing: Bool
}

extension SecureStorageClient {
	public typealias DisableCloudProfileSync = @Sendable (ProfileID) throws -> Void
	public typealias SaveProfileSnapshot = @Sendable (Profile) throws -> Void
	public typealias LoadProfileSnapshotData = @Sendable (ProfileID) throws -> Data?
	public typealias LoadProfileSnapshot = @Sendable (ProfileID) throws -> Profile?
	public typealias LoadProfile = @Sendable (ProfileID) throws -> Profile?
	public typealias DeleteProfile = @Sendable (ProfileID) throws -> Void

	public typealias SaveMnemonicForFactorSource = @Sendable (PrivateHierarchicalDeterministicFactorSource) throws -> Void
	public typealias LoadMnemonicByFactorSourceID = @Sendable (LoadMnemonicByFactorSourceIDRequest) throws -> MnemonicWithPassphrase?
	public typealias ContainsMnemonicIdentifiedByFactorSourceID = @Sendable (FactorSourceIDFromHash) -> Bool

	#if DEBUG
	public typealias GetAllMnemonics = @Sendable () -> [KeyedMnemonicWithPassphrase]
	#endif

	public typealias DeleteMnemonicByFactorSourceID = @Sendable (FactorSourceIDFromHash) throws -> Void
	public typealias DeleteProfileAndMnemonicsByFactorSourceIDs = @Sendable (ProfileID, _ keepInICloudIfPresent: Bool) throws -> Void

	public typealias LoadProfileHeaderList = @Sendable () throws -> Profile.HeaderList?
	public typealias SaveProfileHeaderList = @Sendable (Profile.HeaderList) throws -> Void
	public typealias DeleteProfileHeaderList = @Sendable () throws -> Void

	public typealias LoadDeviceInfo = @Sendable () throws -> DeviceInfo?
	public typealias SaveDeviceInfo = @Sendable (DeviceInfo) throws -> Void

	public typealias SaveRadixConnectRelaySession = @Sendable (SessionId, BagOfBytes) throws -> Void
	public typealias LoadRadixConnectRelaySession = @Sendable (SessionId) throws -> BagOfBytes?

	/// See https://radixdlt.atlassian.net/l/cp/fmoH9KcN
	public typealias DeprecatedLoadDeviceID = @Sendable () throws -> DeviceID?
	/// See https://radixdlt.atlassian.net/l/cp/fmoH9KcN
	public typealias DeleteDeprecatedDeviceID = @Sendable () -> Void

	public typealias LoadP2PLinks = @Sendable () throws -> P2PLinks?
	public typealias SaveP2PLinks = @Sendable (P2PLinks) throws -> Void

	public typealias LoadP2PLinksPrivateKey = @Sendable () throws -> Curve25519.PrivateKey?
	public typealias SaveP2PLinksPrivateKey = @Sendable (Curve25519.PrivateKey) throws -> Void

	public typealias KeychainChanged = @Sendable () -> AnyAsyncSequence<Void>

	public enum LoadMnemonicPurpose: Sendable, Hashable, CustomStringConvertible {
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

		public var description: String {
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
	public func loadMnemonic(
		factorSourceID: FactorSourceIDFromHash,
		notifyIfMissing: Bool = true
	) throws -> MnemonicWithPassphrase? {
		try self.loadMnemonicByFactorSourceID(.init(factorSourceID: factorSourceID, notifyIfMissing: notifyIfMissing))
	}

	@Sendable
	public func deleteProfileAndMnemonicsByFactorSourceIDs(profileID: Profile.ID, keepInICloudIfPresent: Bool) throws {
		try deleteProfileAndMnemonicsByFactorSourceIDs(profileID, keepInICloudIfPresent)
	}
}

#if DEBUG

// MARK: - KeyedMnemonicWithPassphrase
public struct KeyedMnemonicWithPassphrase: Sendable, Hashable {
	public let factorSourceID: FactorSourceIDFromHash
	public let mnemonicWithPassphrase: MnemonicWithPassphrase
}
#endif

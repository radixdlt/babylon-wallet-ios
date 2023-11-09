// MARK: - SecureStorageClient
public struct SecureStorageClient: Sendable {
	public var saveProfileSnapshot: SaveProfileSnapshot
	public var loadProfileSnapshotData: LoadProfileSnapshotData
	public var loadProfileSnapshot: LoadProfileSnapshot
	public var loadProfile: LoadProfile

	public var saveMnemonicForFactorSource: SaveMnemonicForFactorSource
	public var loadMnemonicByFactorSourceID: LoadMnemonicByFactorSourceID
	public var containsMnemonicIdentifiedByFactorSourceID: ContainsMnemonicIdentifiedByFactorSourceID

	public var deleteMnemonicByFactorSourceID: DeleteMnemonicByFactorSourceID
	public var deleteProfileAndMnemonicsByFactorSourceIDs: DeleteProfileAndMnemonicsByFactorSourceIDs

	public var updateIsCloudProfileSyncEnabled: UpdateIsCloudProfileSyncEnabled

	public var loadProfileHeaderList: LoadProfileHeaderList
	public var saveProfileHeaderList: SaveProfileHeaderList
	public var deleteProfileHeaderList: DeleteProfileHeaderList

	public var loadDeviceInfo: LoadDeviceInfo
	public var saveDeviceInfo: SaveDeviceInfo

	/// See https://radixdlt.atlassian.net/l/cp/fmoH9KcN
	public var deprecatedLoadDeviceID: DeprecatedLoadDeviceID
	/// See https://radixdlt.atlassian.net/l/cp/fmoH9KcN
	public var deleteDeprecatedDeviceID: DeleteDeprecatedDeviceID

	#if DEBUG
	public var getAllMnemonics: GetAllMnemonics
	#endif

	#if DEBUG
	init(
		saveProfileSnapshot: @escaping SaveProfileSnapshot,
		loadProfileSnapshotData: @escaping LoadProfileSnapshotData,
		loadProfileSnapshot: @escaping LoadProfileSnapshot,
		loadProfile: @escaping LoadProfile,
		saveMnemonicForFactorSource: @escaping SaveMnemonicForFactorSource,
		loadMnemonicByFactorSourceID: @escaping LoadMnemonicByFactorSourceID,
		containsMnemonicIdentifiedByFactorSourceID: @escaping ContainsMnemonicIdentifiedByFactorSourceID,
		deleteMnemonicByFactorSourceID: @escaping DeleteMnemonicByFactorSourceID,
		deleteProfileAndMnemonicsByFactorSourceIDs: @escaping DeleteProfileAndMnemonicsByFactorSourceIDs,
		updateIsCloudProfileSyncEnabled: @escaping UpdateIsCloudProfileSyncEnabled,
		loadProfileHeaderList: @escaping LoadProfileHeaderList,
		saveProfileHeaderList: @escaping SaveProfileHeaderList,
		deleteProfileHeaderList: @escaping DeleteProfileHeaderList,
		loadDeviceInfo: @escaping LoadDeviceInfo,
		saveDeviceInfo: @escaping SaveDeviceInfo,
		deprecatedLoadDeviceID: @escaping DeprecatedLoadDeviceID,
		deleteDeprecatedDeviceID: @escaping DeleteDeprecatedDeviceID,
		getAllMnemonics: @escaping GetAllMnemonics
	) {
		self.saveProfileSnapshot = saveProfileSnapshot
		self.loadProfileSnapshotData = loadProfileSnapshotData
		self.loadProfileSnapshot = loadProfileSnapshot
		self.loadProfile = loadProfile
		self.saveMnemonicForFactorSource = saveMnemonicForFactorSource
		self.loadMnemonicByFactorSourceID = loadMnemonicByFactorSourceID
		self.containsMnemonicIdentifiedByFactorSourceID = containsMnemonicIdentifiedByFactorSourceID
		self.deleteMnemonicByFactorSourceID = deleteMnemonicByFactorSourceID
		self.deleteProfileAndMnemonicsByFactorSourceIDs = deleteProfileAndMnemonicsByFactorSourceIDs
		self.updateIsCloudProfileSyncEnabled = updateIsCloudProfileSyncEnabled
		self.loadProfileHeaderList = loadProfileHeaderList
		self.saveProfileHeaderList = saveProfileHeaderList
		self.deleteProfileHeaderList = deleteProfileHeaderList
		self.loadDeviceInfo = loadDeviceInfo
		self.saveDeviceInfo = saveDeviceInfo
		self.deprecatedLoadDeviceID = deprecatedLoadDeviceID
		self.deleteDeprecatedDeviceID = deleteDeprecatedDeviceID
		self.getAllMnemonics = getAllMnemonics
	}
	#else

	init(
		saveProfileSnapshot: @escaping SaveProfileSnapshot,
		loadProfileSnapshotData: @escaping LoadProfileSnapshotData,
		loadProfileSnapshot: @escaping LoadProfileSnapshot,
		loadProfile: @escaping LoadProfile,
		saveMnemonicForFactorSource: @escaping SaveMnemonicForFactorSource,
		loadMnemonicByFactorSourceID: @escaping LoadMnemonicByFactorSourceID,
		containsMnemonicIdentifiedByFactorSourceID: @escaping ContainsMnemonicIdentifiedByFactorSourceID,
		deleteMnemonicByFactorSourceID: @escaping DeleteMnemonicByFactorSourceID,
		deleteProfileAndMnemonicsByFactorSourceIDs: @escaping DeleteProfileAndMnemonicsByFactorSourceIDs,
		updateIsCloudProfileSyncEnabled: @escaping UpdateIsCloudProfileSyncEnabled,
		loadProfileHeaderList: @escaping LoadProfileHeaderList,
		saveProfileHeaderList: @escaping SaveProfileHeaderList,
		deleteProfileHeaderList: @escaping DeleteProfileHeaderList,
		loadDeviceInfo: @escaping LoadDeviceInfo,
		saveDeviceInfo: @escaping SaveDeviceInfo,
		deprecatedLoadDeviceID: @escaping DeprecatedLoadDeviceID,
		deleteDeprecatedDeviceID: @escaping DeleteDeprecatedDeviceID
	) {
		self.saveProfileSnapshot = saveProfileSnapshot
		self.loadProfileSnapshotData = loadProfileSnapshotData
		self.loadProfileSnapshot = loadProfileSnapshot
		self.loadProfile = loadProfile
		self.saveMnemonicForFactorSource = saveMnemonicForFactorSource
		self.loadMnemonicByFactorSourceID = loadMnemonicByFactorSourceID
		self.containsMnemonicIdentifiedByFactorSourceID = containsMnemonicIdentifiedByFactorSourceID
		self.deleteMnemonicByFactorSourceID = deleteMnemonicByFactorSourceID
		self.deleteProfileAndMnemonicsByFactorSourceIDs = deleteProfileAndMnemonicsByFactorSourceIDs
		self.updateIsCloudProfileSyncEnabled = updateIsCloudProfileSyncEnabled
		self.loadProfileHeaderList = loadProfileHeaderList
		self.saveProfileHeaderList = saveProfileHeaderList
		self.deleteProfileHeaderList = deleteProfileHeaderList
		self.loadDeviceInfo = loadDeviceInfo
		self.saveDeviceInfo = saveDeviceInfo
		self.deprecatedLoadDeviceID = deprecatedLoadDeviceID
		self.deleteDeprecatedDeviceID = deleteDeprecatedDeviceID
	}
	#endif // DEBUG
}

extension SecureStorageClient {
	public typealias UpdateIsCloudProfileSyncEnabled = @Sendable (ProfileSnapshot.Header.ID, CloudProfileSyncActivation) throws -> Void
	public typealias SaveProfileSnapshot = @Sendable (ProfileSnapshot) throws -> Void
	public typealias LoadProfileSnapshotData = @Sendable (ProfileSnapshot.Header.ID) throws -> Data?
	public typealias LoadProfileSnapshot = @Sendable (ProfileSnapshot.Header.ID) throws -> ProfileSnapshot?
	public typealias LoadProfile = @Sendable (ProfileSnapshot.Header.ID) throws -> Profile?

	public typealias SaveMnemonicForFactorSource = @Sendable (PrivateHDFactorSource) throws -> Void
	public typealias LoadMnemonicByFactorSourceID = @Sendable (FactorSourceID.FromHash, LoadMnemonicPurpose, _ notifyIfMissing: Bool) throws -> MnemonicWithPassphrase?
	public typealias ContainsMnemonicIdentifiedByFactorSourceID = @Sendable (FactorSourceID.FromHash) -> Bool

	#if DEBUG
	public typealias GetAllMnemonics = @Sendable () -> [KeyedMnemonicWithPassphrase]
	#endif

	public typealias DeleteMnemonicByFactorSourceID = @Sendable (FactorSourceID.FromHash) throws -> Void
	public typealias DeleteProfileAndMnemonicsByFactorSourceIDs = @Sendable (ProfileSnapshot.Header.ID, _ keepInICloudIfPresent: Bool) throws -> Void

	public typealias LoadProfileHeaderList = @Sendable () throws -> ProfileSnapshot.HeaderList?
	public typealias SaveProfileHeaderList = @Sendable (ProfileSnapshot.HeaderList) throws -> Void
	public typealias DeleteProfileHeaderList = @Sendable () throws -> Void

	public typealias LoadDeviceInfo = @Sendable () throws -> DeviceInfo?
	public typealias SaveDeviceInfo = @Sendable (DeviceInfo) throws -> Void

	/// See https://radixdlt.atlassian.net/l/cp/fmoH9KcN
	public typealias DeprecatedLoadDeviceID = @Sendable () throws -> DeviceID?
	/// See https://radixdlt.atlassian.net/l/cp/fmoH9KcN
	public typealias DeleteDeprecatedDeviceID = @Sendable () -> Void

	public enum LoadMnemonicPurpose: Sendable, Hashable, CustomStringConvertible {
		case signTransaction
		case signAuthChallenge
		case importOlympiaAccounts

		case displaySeedPhrase
		case createEntity(kind: EntityKind)

		/// Check if account(/persona) recovery is needed
		case checkingAccounts

		case createSignAuthKey

		case updateAccountMetadata

		public var description: String {
			switch self {
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
			case .createSignAuthKey:
				"createSignAuthKey"
			case .updateAccountMetadata:
				"updateAccountMetadata"
			}
		}
	}
}

extension SecureStorageClient {
	@Sendable
	public func loadMnemonic(
		factorSourceID: FactorSourceID.FromHash,
		purpose: LoadMnemonicPurpose,
		notifyIfMissing: Bool = true
	) throws -> MnemonicWithPassphrase? {
		try self.loadMnemonicByFactorSourceID(factorSourceID, purpose, notifyIfMissing)
	}

	@Sendable
	public func deleteProfileAndMnemonicsByFactorSourceIDs(profileID: Profile.ID, keepInICloudIfPresent: Bool) throws {
		try deleteProfileAndMnemonicsByFactorSourceIDs(profileID, keepInICloudIfPresent)
	}
}

// MARK: - CloudProfileSyncActivation
public enum CloudProfileSyncActivation: Sendable, Hashable {
	/// iCloud sync was enabled, user request to disable it.
	case disable

	/// iCloud sync was disabled, user request to enable it.
	case enable
}

#if DEBUG

// MARK: - KeyedMnemonicWithPassphrase
public struct KeyedMnemonicWithPassphrase: Sendable, Hashable {
	public let factorSourceID: FactorSourceID.FromHash
	public let mnemonicWithPassPhrase: MnemonicWithPassphrase
}
#endif

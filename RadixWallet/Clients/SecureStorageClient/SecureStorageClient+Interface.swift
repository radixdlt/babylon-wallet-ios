// MARK: - SecureStorageClient
public struct SecureStorageClient: Sendable {
	public var saveProfileSnapshot: SaveProfileSnapshot
	public var loadProfileSnapshotData: LoadProfileSnapshotData

	public var saveMnemonicForFactorSource: SaveMnemonicForFactorSource
	public var loadMnemonicByFactorSourceID: LoadMnemonicByFactorSourceID
	public var containsMnemonicIdentifiedByFactorSourceID: ContainsMnemonicIdentifiedByFactorSourceID

	public var deleteMnemonicByFactorSourceID: DeleteMnemonicByFactorSourceID
	public var deleteProfileAndMnemonicsByFactorSourceIDs: DeleteProfileAndMnemonicsByFactorSourceIDs

	public var updateIsCloudProfileSyncEnabled: UpdateIsCloudProfileSyncEnabled

	public var loadProfileHeaderList: LoadProfileHeaderList
	public var saveProfileHeaderList: SaveProfileHeaderList
	public var deleteProfileHeaderList: DeleteProfileHeaderList

	public var getDeviceInfoSetIfNil: GetDeviceInfoSetIfNil
	public var loadDeviceInfo: LoadDeviceInfo
	public var saveDeviceInfo: SaveDeviceInfo

	/// See https://radixdlt.atlassian.net/l/cp/fmoH9KcN
	public var deprecatedLoadDeviceID: DeprecatedLoadDeviceID
	/// See https://radixdlt.atlassian.net/l/cp/fmoH9KcN
	public var deleteDeprecatedDeviceID: DeleteDeprecatedDeviceID
}

extension SecureStorageClient {
	public typealias UpdateIsCloudProfileSyncEnabled = @Sendable (ProfileSnapshot.Header.ID, CloudProfileSyncActivation) throws -> Void
	public typealias SaveProfileSnapshot = @Sendable (ProfileSnapshot) throws -> Void
	public typealias LoadProfileSnapshotData = @Sendable (ProfileSnapshot.Header.ID) throws -> Data?

	public typealias SaveMnemonicForFactorSource = @Sendable (PrivateHDFactorSource) throws -> Void
	public typealias LoadMnemonicByFactorSourceID = @Sendable (FactorSourceID.FromHash, LoadMnemonicPurpose) throws -> MnemonicWithPassphrase?
	public typealias ContainsMnemonicIdentifiedByFactorSourceID = @Sendable (FactorSourceID.FromHash) -> Bool

	public typealias DeleteMnemonicByFactorSourceID = @Sendable (FactorSourceID.FromHash) throws -> Void
	public typealias DeleteProfileAndMnemonicsByFactorSourceIDs = @Sendable (ProfileSnapshot.Header.ID, _ keepInICloudIfPresent: Bool) throws -> Void

	public typealias LoadProfileHeaderList = @Sendable () throws -> ProfileSnapshot.HeaderList?
	public typealias SaveProfileHeaderList = @Sendable (ProfileSnapshot.HeaderList) throws -> Void
	public typealias DeleteProfileHeaderList = @Sendable () throws -> Void

	public typealias GetDeviceInfoSetIfNil = @Sendable (DeviceInfo) throws -> DeviceInfo
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

// MARK: - CloudProfileSyncActivation
public enum CloudProfileSyncActivation: Sendable, Hashable {
	/// iCloud sync was enabled, user request to disable it.
	case disable

	/// iCloud sync was disabled, user request to enable it.
	case enable
}

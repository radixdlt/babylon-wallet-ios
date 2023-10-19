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

	public var getDeviceIdentifierSetIfNil: GetDeviceIdentifierSetIfNil
	public var loadDeviceIdentifier: LoadDeviceIdentifier
	public var saveDeviceIdentifier: SaveDeviceIdentifier
}

extension SecureStorageClient {
	public typealias UpdateIsCloudProfileSyncEnabled = @Sendable (ProfileSnapshot.Header.ID, CloudProfileSyncActivation) async throws -> Void
	public typealias SaveProfileSnapshot = @Sendable (ProfileSnapshot) async throws -> Void
	public typealias LoadProfileSnapshotData = @Sendable (ProfileSnapshot.Header.ID) throws -> Data?

	public typealias SaveMnemonicForFactorSource = @Sendable (PrivateHDFactorSource) async throws -> Void
	public typealias LoadMnemonicByFactorSourceID = @Sendable (FactorSourceID.FromHash, LoadMnemonicPurpose) throws -> MnemonicWithPassphrase?
	public typealias ContainsMnemonicIdentifiedByFactorSourceID = @Sendable (FactorSourceID.FromHash) -> Bool

	public typealias DeleteMnemonicByFactorSourceID = @Sendable (FactorSourceID.FromHash) async throws -> Void
	public typealias DeleteProfileAndMnemonicsByFactorSourceIDs = @Sendable (ProfileSnapshot.Header.ID, _ keepInICloudIfPresent: Bool) async throws -> Void

	public typealias LoadProfileHeaderList = @Sendable () throws -> ProfileSnapshot.HeaderList?
	public typealias SaveProfileHeaderList = @Sendable (ProfileSnapshot.HeaderList) async throws -> Void
	public typealias DeleteProfileHeaderList = @Sendable () async throws -> Void

	public typealias GetDeviceIdentifierSetIfNil = @Sendable (UUID) async throws -> UUID
	public typealias LoadDeviceIdentifier = @Sendable () throws -> UUID?
	public typealias SaveDeviceIdentifier = @Sendable (UUID) async throws -> Void

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
	public func saveDeviceIdentifierIfNeeded(
		_ deviceID: UUID
	) async throws {
		_ = try await getDeviceIdentifierSetIfNil(deviceID)
	}
}

// MARK: - CloudProfileSyncActivation
public enum CloudProfileSyncActivation: Sendable, Hashable {
	/// iCloud sync was enabled, user request to disable it.
	case disable

	/// iCloud sync was disabled, user request to enable it.
	case enable
}

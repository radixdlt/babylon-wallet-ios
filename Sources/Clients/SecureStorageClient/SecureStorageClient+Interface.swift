import ClientPrelude
import Profile

// MARK: - SecureStorageClient
public struct SecureStorageClient: Sendable {
	public var saveProfileSnapshot: SaveProfileSnapshot
	public var loadProfileSnapshotData: LoadProfileSnapshotData

	public var saveMnemonicForFactorSource: SaveMnemonicForFactorSource
	public var loadMnemonicByFactorSourceID: LoadMnemonicByFactorSourceID

	public var deleteMnemonicByFactorSourceID: DeleteMnemonicByFactorSourceID
	public var deleteProfileAndMnemonicsIfSpecified: DeleteProfileAndMnemonicsIfSpecified

	public var updateIsCloudProfileSyncEnabled: UpdateIsCloudProfileSyncEnabled

	public var loadProfileHeaderList: LoadProfileHeaderList
	public var saveProfileHeaderList: SaveProfileHeaderList
	public var deleteProfileHeaderList: DeleteProfileHeaderList

	public var loadDeviceIdentifier: LoadDeviceIdentifier
	public var saveDeviceIdentifier: SaveDeviceIdentifier
}

// MARK: - DeleteProfileRequest
public struct DeleteProfileRequest: Sendable, Hashable {
	public let profileID: ProfileSnapshot.Header.ID
	public let keepInICloudIfPresent: Bool
	public let deleteMnemonics: Bool
	public init(profileID: ProfileSnapshot.Header.ID, keepInICloudIfPresent: Bool, deleteMnemonics: Bool) {
		self.profileID = profileID
		self.keepInICloudIfPresent = keepInICloudIfPresent
		self.deleteMnemonics = deleteMnemonics
	}
}

extension SecureStorageClient {
	public typealias UpdateIsCloudProfileSyncEnabled = @Sendable (ProfileSnapshot.Header.ID, CloudProfileSyncActivation) async throws -> Void
	public typealias SaveProfileSnapshot = @Sendable (ProfileSnapshot) async throws -> Void
	public typealias LoadProfileSnapshotData = @Sendable (ProfileSnapshot.Header.ID) async throws -> Data?

	public typealias SaveMnemonicForFactorSource = @Sendable (PrivateHDFactorSource) async throws -> Void
	public typealias LoadMnemonicByFactorSourceID = @Sendable (FactorSourceID.FromHash, LoadMnemonicPurpose) async throws -> MnemonicWithPassphrase?

	public typealias DeleteMnemonicByFactorSourceID = @Sendable (FactorSourceID.FromHash) async throws -> Void
	public typealias DeleteProfileAndMnemonicsIfSpecified = @Sendable (DeleteProfileRequest) async throws -> Void

	public typealias LoadProfileHeaderList = @Sendable () async throws -> ProfileSnapshot.HeaderList?
	public typealias SaveProfileHeaderList = @Sendable (ProfileSnapshot.HeaderList) async throws -> Void
	public typealias DeleteProfileHeaderList = @Sendable () async throws -> Void

	public typealias LoadDeviceIdentifier = @Sendable () async throws -> UUID?
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
				return "importOlympiaAccounts"
			case .displaySeedPhrase:
				return "displaySeedPhrase"
			case let .createEntity(kind):
				return "createEntity.\(kind)"
			case .signAuthChallenge:
				return "signAuthChallenge"
			case .signTransaction:
				return "signTransaction"
			case .checkingAccounts:
				return "checkingAccounts"
			case .createSignAuthKey:
				return "createSignAuthKey"
			case .updateAccountMetadata:
				return "updateAccountMetadata"
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

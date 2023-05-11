import ClientPrelude
import Profile

// MARK: - SecureStorageClient
public struct SecureStorageClient: Sendable {
	public var saveProfileSnapshot: SaveProfileSnapshot
	public var loadProfileSnapshotData: LoadProfileSnapshotData

	public var saveMnemonicForFactorSource: SaveMnemonicForFactorSource
	public var loadMnemonicByFactorSourceID: LoadMnemonicByFactorSourceID

	public var deleteMnemonicByFactorSourceID: DeleteMnemonicByFactorSourceID
	public var deleteProfileAndMnemonicsByFactorSourceIDs: DeleteProfileAndMnemonicsByFactorSourceIDs

	public var updateIsCloudProfileSyncEnabled: UpdateIsCloudProfileSyncEnabled

	public var loadProfileHeaderList: LoadProfileHeaderList
	public var saveProfileHeaderList: SaveProfileHeaderList
	public var deleteProfileHeaderList: DeleteProfileHeaderList

	public var loadDeviceIdentifier: LoadDeviceIdentifier
}

extension SecureStorageClient {
	public typealias UpdateIsCloudProfileSyncEnabled = @Sendable (ProfileSnapshot.Header.ID, CloudProfileSyncActivation) async throws -> Void
	public typealias SaveProfileSnapshot = @Sendable (ProfileSnapshot) async throws -> Void
	public typealias LoadProfileSnapshotData = @Sendable (ProfileSnapshot.Header.ID) async throws -> Data?

	public typealias SaveMnemonicForFactorSource = @Sendable (PrivateHDFactorSource) async throws -> Void
	public typealias LoadMnemonicByFactorSourceID = @Sendable (FactorSource.ID, LoadMnemonicPurpose) async throws -> MnemonicWithPassphrase?

	public typealias DeleteMnemonicByFactorSourceID = @Sendable (FactorSource.ID) async throws -> Void
	public typealias DeleteProfileAndMnemonicsByFactorSourceIDs = @Sendable (ProfileSnapshot.Header.ID, _ keepInICloudIfPresent: Bool) async throws -> Void

	public typealias LoadProfileHeaderList = @Sendable () async throws -> NonEmpty<IdentifiedArrayOf<ProfileSnapshot.Header>>?
	public typealias SaveProfileHeaderList = @Sendable (ProfileSnapshot.HeaderList, _ iCloudSyncEnabled: Bool) async throws -> Void
	public typealias DeleteProfileHeaderList = @Sendable () async throws -> Void

	public typealias LoadDeviceIdentifier = @Sendable () async throws -> UUID

	public enum LoadMnemonicPurpose: Sendable, Hashable, CustomStringConvertible {
		case signTransaction
		case signAuthChallenge
		case importOlympiaAccounts
		case createEntity(kind: EntityKind)

		/// Check if account(/persona) recovery is needed
		case checkingAccounts

		case createSignAuthKey
		#if DEBUG
		case debugOnlyInspect
		#endif

		public var description: String {
			switch self {
			case .importOlympiaAccounts:
				return "importOlympiaAccounts"
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
			#if DEBUG
			case .debugOnlyInspect:
				return "debugOnlyInspect"
			#endif
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

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

	public var updateIcloudProfileSync: UpdateIcloudProfileSync
}

extension SecureStorageClient {
	public typealias UpdateIcloudProfileSync = @Sendable (IcloudProfileSyncActivation) async throws -> Void
	public typealias SaveProfileSnapshot = @Sendable (ProfileSnapshot) async throws -> Void
	public typealias LoadProfileSnapshotData = @Sendable () async throws -> Data?

	public typealias SaveMnemonicForFactorSource = @Sendable (PrivateHDFactorSource) async throws -> Void
	public typealias LoadMnemonicByFactorSourceID = @Sendable (FactorSource.ID, LoadMnemonicPurpose) async throws -> MnemonicWithPassphrase?

	public typealias DeleteMnemonicByFactorSourceID = @Sendable (FactorSource.ID) async throws -> Void
	public typealias DeleteProfileAndMnemonicsByFactorSourceIDs = @Sendable (_ keepIcloudIfPresent: Bool) async throws -> Void

	public enum LoadMnemonicPurpose: Sendable, Equatable, CustomStringConvertible {
		case signTransaction
		case signAuthChallenge
		case importOlympiaAccounts
		case createEntity(kind: EntityKind)

		/// Check if account(/persona) recovery is needed
		case checkingAccounts

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
			#if DEBUG
			case .debugOnlyInspect:
				return "debugOnlyInspect"
			#endif
			}
		}
	}
}

// MARK: - IcloudProfileSyncActivation
public enum IcloudProfileSyncActivation: Sendable, Hashable {
	/// iCloud sync was enabled, user request to disable it.
	case disable

	/// iCloud sync was disabled, user request to enable it.
	case enable
}

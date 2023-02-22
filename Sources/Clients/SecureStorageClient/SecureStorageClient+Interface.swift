import ClientPrelude
import Profile

// MARK: - SecureStorageClient
public struct SecureStorageClient: Sendable {
	public var addNewProfileSnapshot: AddNewProfileSnapshot
	public var updateProfileSnapshot: UpdateProfileSnapshot
	public var loadProfileSnapshotData: LoadProfileSnapshotData

	public var addNewMnemonicForFactorSource: AddNewMnemonicForFactorSource
	public var loadMnemonicByFactorSourceID: LoadMnemonicByFactorSourceID

	public var deleteMnemonicByFactorSourceID: DeleteMnemonicByFactorSourceID
	public var deleteProfileAndMnemonicsByFactorSourceIDs: DeleteProfileAndMnemonicsByFactorSourceIDs
}

extension SecureStorageClient {
	public typealias AddNewProfileSnapshot = @Sendable (ProfileSnapshot) async throws -> Void
	public typealias UpdateProfileSnapshot = @Sendable (ProfileSnapshot) async throws -> Void
	public typealias LoadProfileSnapshotData = @Sendable () async throws -> Data?

	public typealias AddNewMnemonicForFactorSource = @Sendable (PrivateHDFactorSource) async throws -> Void
	public typealias LoadMnemonicByFactorSourceID = @Sendable (FactorSource.ID, LoadMnemonicPurpose) async throws -> MnemonicWithPassphrase?

	public typealias DeleteMnemonicByFactorSourceID = @Sendable (FactorSource.ID) async throws -> Void
	public typealias DeleteProfileAndMnemonicsByFactorSourceIDs = @Sendable () async throws -> Void

	public enum LoadMnemonicPurpose: Sendable, Equatable {
		case deleteSingleMnemonic
		case deleteProfileAndAllMnemonics
		case signTransaction
		case signAuthChallenge
		case createEntity(kind: EntityKind)
		#if DEBUG
		case debugOnlyInspect
		#endif
	}
}

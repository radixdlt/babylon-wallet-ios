import ClientPrelude

extension DependencyValues {
	public var secureStorageClient: SecureStorageClient {
		get { self[SecureStorageClient.self] }
		set { self[SecureStorageClient.self] = newValue }
	}
}

// MARK: - SecureStorageClient + TestDependencyKey
extension SecureStorageClient: TestDependencyKey {
	public static let noop: Self = .init(
		addNewProfileSnapshot: { _ in },
		updateProfileSnapshot: { _ in },
		loadProfileSnapshotData: { nil },
		addNewMnemonicForFactorSource: { _ in },
		loadMnemonicByFactorSourceID: { _, _ in nil },
		deleteMnemonicByFactorSourceID: { _ in },
		deleteProfileAndMnemonicsByFactorSourceIDs: {}
	)

	public static let previewValue: Self = .noop

	public static let testValue = Self(
		addNewProfileSnapshot: unimplemented("\(Self.self).addNewProfileSnapshot"),
		updateProfileSnapshot: unimplemented("\(Self.self).updateProfileSnapshot"),
		loadProfileSnapshotData: unimplemented("\(Self.self).loadProfileSnapshotData"),
		addNewMnemonicForFactorSource: unimplemented("\(Self.self).addNewMnemonicForFactorSource"),
		loadMnemonicByFactorSourceID: unimplemented("\(Self.self).loadMnemonicByFactorSourceID"),
		deleteMnemonicByFactorSourceID: unimplemented("\(Self.self).deleteMnemonicByFactorSourceID"),
		deleteProfileAndMnemonicsByFactorSourceIDs: unimplemented("\(Self.self).deleteProfileAndMnemonicsByFactorSourceIDs")
	)
}

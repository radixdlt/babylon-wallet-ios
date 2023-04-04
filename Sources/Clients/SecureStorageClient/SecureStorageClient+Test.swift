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
		saveProfileSnapshot: { _ in },
		loadProfileSnapshotData: { nil },
		saveMnemonicForFactorSource: { _ in },
		loadMnemonicByFactorSourceID: { _, _ in nil },
		deleteMnemonicByFactorSourceID: { _ in },
		deleteProfileAndMnemonicsByFactorSourceIDs: { _ in },
		setIsIcloudProfileSyncEnabled: { _ in }
	)

	public static let previewValue: Self = .noop

	public static let testValue = Self(
		saveProfileSnapshot: unimplemented("\(Self.self).saveProfileSnapshot"),
		loadProfileSnapshotData: unimplemented("\(Self.self).loadProfileSnapshotData"),
		saveMnemonicForFactorSource: unimplemented("\(Self.self).saveMnemonicForFactorSource"),
		loadMnemonicByFactorSourceID: unimplemented("\(Self.self).loadMnemonicByFactorSourceID"),
		deleteMnemonicByFactorSourceID: unimplemented("\(Self.self).deleteMnemonicByFactorSourceID"),
		deleteProfileAndMnemonicsByFactorSourceIDs: unimplemented("\(Self.self).deleteProfileAndMnemonicsByFactorSourceIDs"),
		setIsIcloudProfileSyncEnabled: unimplemented("\(Self.self).setIsIcloudProfileSyncEnabled")
	)
}

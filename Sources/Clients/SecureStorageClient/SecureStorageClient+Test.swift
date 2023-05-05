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
		loadProfileSnapshotData: { _ in nil },
		saveMnemonicForFactorSource: { _ in },
		loadMnemonicByFactorSourceID: { _, _ in nil },
		deleteMnemonicByFactorSourceID: { _ in },
		deleteProfileAndMnemonicsByFactorSourceIDs: { _, _ in },
		updateIsCloudProfileSyncEnabled: { _, _ in },
		loadProfileHeaderList: { nil },
		saveProfileHeaderList: { _ in },
		deleteProfileHeaderList: {}
	)

	public static let previewValue: Self = .noop

	public static let testValue = Self(
		saveProfileSnapshot: unimplemented("\(Self.self).saveProfileSnapshot"),
		loadProfileSnapshotData: unimplemented("\(Self.self).loadProfileSnapshotData"),
		saveMnemonicForFactorSource: unimplemented("\(Self.self).saveMnemonicForFactorSource"),
		loadMnemonicByFactorSourceID: unimplemented("\(Self.self).loadMnemonicByFactorSourceID"),
		deleteMnemonicByFactorSourceID: unimplemented("\(Self.self).deleteMnemonicByFactorSourceID"),
		deleteProfileAndMnemonicsByFactorSourceIDs: unimplemented("\(Self.self).deleteProfileAndMnemonicsByFactorSourceIDs"),
		updateIsCloudProfileSyncEnabled: unimplemented("\(Self.self).updateIsCloudProfileSyncEnabled"),
		loadProfileHeaderList: unimplemented("\(Self.self).loadProfileHeaderList"),
		saveProfileHeaderList: unimplemented("\(Self.self).saveProfileHeaderList"),
		deleteProfileHeaderList: unimplemented("\(Self.self).deleteProfileHeaderList")
	)
}

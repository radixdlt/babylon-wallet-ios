
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
		containsMnemonicIdentifiedByFactorSourceID: { _ in false },
		deleteMnemonicByFactorSourceID: { _ in },
		deleteProfileAndMnemonicsByFactorSourceIDs: { _, _ in },
		updateIsCloudProfileSyncEnabled: { _, _ in },
		loadProfileHeaderList: { nil },
		saveProfileHeaderList: { _ in },
		deleteProfileHeaderList: {},
		getDeviceInfoSetIfNil: { $0 },
		loadDeviceInfo: { nil },
		saveDeviceInfo: { _ in },
		deprecatedLoadDeviceID: { nil },
		deleteDeprecatedDeviceID: {}
	)

	public static let previewValue: Self = .noop

	public static let testValue = Self(
		saveProfileSnapshot: unimplemented("\(Self.self).saveProfileSnapshot"),
		loadProfileSnapshotData: unimplemented("\(Self.self).loadProfileSnapshotData"),
		saveMnemonicForFactorSource: unimplemented("\(Self.self).saveMnemonicForFactorSource"),
		loadMnemonicByFactorSourceID: unimplemented("\(Self.self).loadMnemonicByFactorSourceID"),
		containsMnemonicIdentifiedByFactorSourceID: unimplemented("\(Self.self).containsMnemonicIdentifiedByFactorSourceID"),
		deleteMnemonicByFactorSourceID: unimplemented("\(Self.self).deleteMnemonicByFactorSourceID"),
		deleteProfileAndMnemonicsByFactorSourceIDs: unimplemented("\(Self.self).deleteProfileMnemonicsByFactorSourceIDs"),
		updateIsCloudProfileSyncEnabled: unimplemented("\(Self.self).updateIsCloudProfileSyncEnabled"),
		loadProfileHeaderList: unimplemented("\(Self.self).loadProfileHeaderList"),
		saveProfileHeaderList: unimplemented("\(Self.self).saveProfileHeaderList"),
		deleteProfileHeaderList: unimplemented("\(Self.self).deleteProfileHeaderList"),
		getDeviceInfoSetIfNil: unimplemented("\(Self.self).getDeviceInfoSetIfNil"),
		loadDeviceInfo: unimplemented("\(Self.self).loadDeviceInfo"),
		saveDeviceInfo: unimplemented("\(Self.self).saveDeviceInfo"),
		deprecatedLoadDeviceID: unimplemented("\(Self.self).deprecatedLoadDeviceID"),
		deleteDeprecatedDeviceID: unimplemented("\(Self.self).deleteDeprecatedDeviceID")
	)
}

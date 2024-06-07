
extension DependencyValues {
	public var secureStorageClient: SecureStorageClient {
		get { self[SecureStorageClient.self] }
		set { self[SecureStorageClient.self] = newValue }
	}
}

// MARK: - SecureStorageClient + TestDependencyKey
extension SecureStorageClient: TestDependencyKey {
	#if DEBUG
	public static let noop = Self(
		saveProfileSnapshot: { _ in },
		loadProfileSnapshotData: { _ in nil },
		loadProfileSnapshot: { _ in nil },
		loadProfile: { _ in nil },
		deleteProfile: { _ in },
		saveMnemonicForFactorSource: { _ in },
		loadMnemonicByFactorSourceID: { _ in nil },
		containsMnemonicIdentifiedByFactorSourceID: { _ in false },
		deleteMnemonicByFactorSourceID: { _ in },
		deleteProfileAndMnemonicsByFactorSourceIDs: { _, _ in },
		disableCloudProfileSync: { _ in },
		loadProfileHeaderList: { nil },
		saveProfileHeaderList: { _ in },
		deleteProfileHeaderList: {},
		loadDeviceInfo: { nil },
		saveDeviceInfo: { _ in },
		deprecatedLoadDeviceID: { nil },
		deleteDeprecatedDeviceID: {},
		loadP2PLinks: { nil },
		saveP2PLinks: { _ in },
		loadP2PLinksPrivateKey: { nil },
		saveP2PLinksPrivateKey: { _ in },
		keychainChanged: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		getAllMnemonics: { [] }
	)
	#else
	public static let noop = Self(
		saveProfileSnapshot: { _ in },
		loadProfileSnapshotData: { _ in nil },
		loadProfileSnapshot: { _ in nil },
		loadProfile: { _ in nil },
		deleteProfile: { _ in },
		saveMnemonicForFactorSource: { _ in },
		loadMnemonicByFactorSourceID: { _ in nil },
		containsMnemonicIdentifiedByFactorSourceID: { _ in false },
		deleteMnemonicByFactorSourceID: { _ in },
		deleteProfileAndMnemonicsByFactorSourceIDs: { _, _ in },
		disableCloudProfileSync: { _ in },
		loadProfileHeaderList: { nil },
		saveProfileHeaderList: { _ in },
		deleteProfileHeaderList: {},
		loadDeviceInfo: { nil },
		saveDeviceInfo: { _ in },
		deprecatedLoadDeviceID: { nil },
		deleteDeprecatedDeviceID: {},
		loadP2PLinks: { nil },
		saveP2PLinks: { _ in },
		loadP2PLinksPrivateKey: { nil },
		saveP2PLinksPrivateKey: { _ in },
		keychainChanged: { AsyncLazySequence([]).eraseToAnyAsyncSequence() }
	)
	#endif // DEBUG

	public static let previewValue = Self.noop

	#if DEBUG
	public static let testValue = Self(
		saveProfileSnapshot: unimplemented("\(Self.self).saveProfileSnapshot"),
		loadProfileSnapshotData: unimplemented("\(Self.self).loadProfileSnapshotData"),
		loadProfileSnapshot: unimplemented("\(Self.self).loadProfileSnapshot"),
		loadProfile: unimplemented("\(Self.self).loadProfile"),
		deleteProfile: unimplemented("\(Self.self).deleteProfile"),
		saveMnemonicForFactorSource: unimplemented("\(Self.self).saveMnemonicForFactorSource"),
		loadMnemonicByFactorSourceID: unimplemented("\(Self.self).loadMnemonicByFactorSourceID"),
		containsMnemonicIdentifiedByFactorSourceID: unimplemented("\(Self.self).containsMnemonicIdentifiedByFactorSourceID"),
		deleteMnemonicByFactorSourceID: unimplemented("\(Self.self).deleteMnemonicByFactorSourceID"),
		deleteProfileAndMnemonicsByFactorSourceIDs: unimplemented("\(Self.self).deleteProfileMnemonicsByFactorSourceIDs"),
		disableCloudProfileSync: unimplemented("\(Self.self).disableCloudProfileSync"),
		loadProfileHeaderList: unimplemented("\(Self.self).loadProfileHeaderList"),
		saveProfileHeaderList: unimplemented("\(Self.self).saveProfileHeaderList"),
		deleteProfileHeaderList: unimplemented("\(Self.self).deleteProfileHeaderList"),
		loadDeviceInfo: unimplemented("\(Self.self).loadDeviceInfo"),
		saveDeviceInfo: unimplemented("\(Self.self).saveDeviceInfo"),
		deprecatedLoadDeviceID: unimplemented("\(Self.self).deprecatedLoadDeviceID"),
		deleteDeprecatedDeviceID: unimplemented("\(Self.self).deleteDeprecatedDeviceID"),
		loadP2PLinks: unimplemented("\(Self.self).loadP2PLinks"),
		saveP2PLinks: unimplemented("\(Self.self).saveP2PLinks"),
		loadP2PLinksPrivateKey: unimplemented("\(Self.self).loadP2PLinksPrivateKey"),
		saveP2PLinksPrivateKey: unimplemented("\(Self.self).saveP2PLinksPrivateKey"),
		keychainChanged: unimplemented("\(Self.self).keychainChanged"),
		getAllMnemonics: unimplemented("\(Self.self).getAllMnemonics")
	)
	#else
	public static let testValue = Self(
		saveProfileSnapshot: unimplemented("\(Self.self).saveProfileSnapshot"),
		loadProfileSnapshotData: unimplemented("\(Self.self).loadProfileSnapshotData"),
		loadProfileSnapshot: unimplemented("\(Self.self).loadProfileSnapshot"),
		loadProfile: unimplemented("\(Self.self).loadProfile"),
		deleteProfile: unimplemented("\(Self.self).deleteProfile"),
		saveMnemonicForFactorSource: unimplemented("\(Self.self).saveMnemonicForFactorSource"),
		loadMnemonicByFactorSourceID: unimplemented("\(Self.self).loadMnemonicByFactorSourceID"),
		containsMnemonicIdentifiedByFactorSourceID: unimplemented("\(Self.self).containsMnemonicIdentifiedByFactorSourceID"),
		deleteMnemonicByFactorSourceID: unimplemented("\(Self.self).deleteMnemonicByFactorSourceID"),
		deleteProfileAndMnemonicsByFactorSourceIDs: unimplemented("\(Self.self).deleteProfileMnemonicsByFactorSourceIDs"),
		disableCloudProfileSync: unimplemented("\(Self.self).disableCloudProfileSync"),
		loadProfileHeaderList: unimplemented("\(Self.self).loadProfileHeaderList"),
		saveProfileHeaderList: unimplemented("\(Self.self).saveProfileHeaderList"),
		deleteProfileHeaderList: unimplemented("\(Self.self).deleteProfileHeaderList"),
		loadDeviceInfo: unimplemented("\(Self.self).loadDeviceInfo"),
		saveDeviceInfo: unimplemented("\(Self.self).saveDeviceInfo"),
		deprecatedLoadDeviceID: unimplemented("\(Self.self).deprecatedLoadDeviceID"),
		deleteDeprecatedDeviceID: unimplemented("\(Self.self).deleteDeprecatedDeviceID"),
		loadP2PLinks: unimplemented("\(Self.self).loadP2PLinks"),
		saveP2PLinks: unimplemented("\(Self.self).saveP2PLinks"),
		loadP2PLinksPrivateKey: unimplemented("\(Self.self).loadP2PLinksPrivateKey"),
		saveP2PLinksPrivateKey: unimplemented("\(Self.self).saveP2PLinksPrivateKey"),
		keychainChanged: unimplemented("\(Self.self).keychainChanged")
	)
	#endif
}


extension DependencyValues {
	var secureStorageClient: SecureStorageClient {
		get { self[SecureStorageClient.self] }
		set { self[SecureStorageClient.self] = newValue }
	}
}

// MARK: - SecureStorageClient + TestDependencyKey
extension SecureStorageClient: TestDependencyKey {
	#if DEBUG
	static let noop = Self(
		loadProfileSnapshotData: { _ in nil },
		saveProfileSnapshotData: { _, _ in },
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
		deleteDeviceInfo: {},
		deprecatedLoadDeviceID: { nil },
		deleteDeprecatedDeviceID: {},
		saveRadixConnectMobileSession: { _, _ in },
		loadRadixConnectMobileSession: { _ in nil },
		loadP2PLinks: { nil },
		saveP2PLinks: { _ in },
		loadP2PLinksPrivateKey: { nil },
		saveP2PLinksPrivateKey: { _ in },
		keychainChanged: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		getAllMnemonics: { [] },
		loadMnemonicDataByFactorSourceID: { _ in nil },
		saveMnemonicForFactorSourceData: { _, _ in },
		containsDataForKey: { _ in false }
	)
	#else
	static let noop = Self(
		loadProfileSnapshotData: { _ in nil },
		saveProfileSnapshotData: { _, _ in },
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
		deleteDeviceInfo: {},
		deprecatedLoadDeviceID: { nil },
		deleteDeprecatedDeviceID: {},
		saveRadixConnectMobileSession: { _, _ in },
		loadRadixConnectMobileSession: { _ in nil },
		loadP2PLinks: { nil },
		saveP2PLinks: { _ in },
		loadP2PLinksPrivateKey: { nil },
		saveP2PLinksPrivateKey: { _ in },
		keychainChanged: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		loadMnemonicDataByFactorSourceID: { _ in nil },
		saveMnemonicForFactorSourceData: { _, _ in },
		containsDataForKey: { _ in false }
	)
	#endif // DEBUG

	static let previewValue = Self.noop

	#if DEBUG
	static let testValue = Self(
		loadProfileSnapshotData: unimplemented("\(Self.self).loadProfileSnapshotData"),
		saveProfileSnapshotData: unimplemented("\(Self.self).saveProfileSnapshotData"),
		deleteProfile: unimplemented("\(Self.self).deleteProfile"),
		saveMnemonicForFactorSource: unimplemented("\(Self.self).saveMnemonicForFactorSource"),
		loadMnemonicByFactorSourceID: unimplemented("\(Self.self).loadMnemonicByFactorSourceID"),
		containsMnemonicIdentifiedByFactorSourceID: noop.containsMnemonicIdentifiedByFactorSourceID,
		deleteMnemonicByFactorSourceID: unimplemented("\(Self.self).deleteMnemonicByFactorSourceID"),
		deleteProfileAndMnemonicsByFactorSourceIDs: unimplemented("\(Self.self).deleteProfileMnemonicsByFactorSourceIDs"),
		disableCloudProfileSync: unimplemented("\(Self.self).disableCloudProfileSync"),
		loadProfileHeaderList: unimplemented("\(Self.self).loadProfileHeaderList"),
		saveProfileHeaderList: unimplemented("\(Self.self).saveProfileHeaderList"),
		deleteProfileHeaderList: unimplemented("\(Self.self).deleteProfileHeaderList"),
		loadDeviceInfo: unimplemented("\(Self.self).loadDeviceInfo"),
		saveDeviceInfo: unimplemented("\(Self.self).saveDeviceInfo"),
		deleteDeviceInfo: unimplemented("\(Self.self).deleteDeviceInfo"),
		deprecatedLoadDeviceID: unimplemented("\(Self.self).deprecatedLoadDeviceID"),
		deleteDeprecatedDeviceID: unimplemented("\(Self.self).deleteDeprecatedDeviceID"),
		saveRadixConnectMobileSession: unimplemented("\(Self.self).saveRadixConnectMobileSession"),
		loadRadixConnectMobileSession: unimplemented("\(Self.self).loadRadixConnectMobileSession"),
		loadP2PLinks: unimplemented("\(Self.self).loadP2PLinks"),
		saveP2PLinks: unimplemented("\(Self.self).saveP2PLinks"),
		loadP2PLinksPrivateKey: unimplemented("\(Self.self).loadP2PLinksPrivateKey"),
		saveP2PLinksPrivateKey: unimplemented("\(Self.self).saveP2PLinksPrivateKey"),
		keychainChanged: noop.keychainChanged,
		getAllMnemonics: noop.getAllMnemonics,
		loadMnemonicDataByFactorSourceID: unimplemented("\(Self.self).keychainChanged"),
		saveMnemonicForFactorSourceData: unimplemented("\(Self.self).saveMnemonicForFactorSourceData"),
		containsDataForKey: unimplemented("\(Self.self).containsDataForKey")
	)
	#else
	static let testValue = Self(
		loadProfileSnapshotData: unimplemented("\(Self.self).loadProfileSnapshotData"),
		saveProfileSnapshotData: unimplemented("\(Self.self).saveProfileSnapshotData"),
		deleteProfile: unimplemented("\(Self.self).deleteProfile"),
		saveMnemonicForFactorSource: unimplemented("\(Self.self).saveMnemonicForFactorSource"),
		loadMnemonicByFactorSourceID: unimplemented("\(Self.self).loadMnemonicByFactorSourceID"),
		containsMnemonicIdentifiedByFactorSourceID: noop.containsMnemonicIdentifiedByFactorSourceID,
		deleteMnemonicByFactorSourceID: unimplemented("\(Self.self).deleteMnemonicByFactorSourceID"),
		deleteProfileAndMnemonicsByFactorSourceIDs: unimplemented("\(Self.self).deleteProfileMnemonicsByFactorSourceIDs"),
		disableCloudProfileSync: unimplemented("\(Self.self).disableCloudProfileSync"),
		loadProfileHeaderList: unimplemented("\(Self.self).loadProfileHeaderList"),
		saveProfileHeaderList: unimplemented("\(Self.self).saveProfileHeaderList"),
		deleteProfileHeaderList: unimplemented("\(Self.self).deleteProfileHeaderList"),
		loadDeviceInfo: unimplemented("\(Self.self).loadDeviceInfo"),
		saveDeviceInfo: unimplemented("\(Self.self).saveDeviceInfo"),
		deleteDeviceInfo: unimplemented("\(Self.self).deleteDeviceInfo"),
		deprecatedLoadDeviceID: unimplemented("\(Self.self).deprecatedLoadDeviceID"),
		deleteDeprecatedDeviceID: unimplemented("\(Self.self).deleteDeprecatedDeviceID"),
		saveRadixConnectMobileSession: unimplemented("\(Self.self).saveRadixConnectMobileSession"),
		loadRadixConnectMobileSession: unimplemented("\(Self.self).loadRadixConnectMobileSession"),
		loadP2PLinks: unimplemented("\(Self.self).loadP2PLinks"),
		saveP2PLinks: unimplemented("\(Self.self).saveP2PLinks"),
		loadP2PLinksPrivateKey: unimplemented("\(Self.self).loadP2PLinksPrivateKey"),
		saveP2PLinksPrivateKey: unimplemented("\(Self.self).saveP2PLinksPrivateKey"),
		keychainChanged: noop.keychainChanged,
		loadMnemonicDataByFactorSourceID: unimplemented("\(Self.self).keychainChanged"),
		saveMnemonicForFactorSourceData: unimplemented("\(Self.self).saveMnemonicForFactorSourceData"),
		containsDataForKey: unimplemented("\(Self.self).containsDataForKey")
	)
	#endif
}


extension DependencyValues {
	public var importLegacyWalletClient: ImportLegacyWalletClient {
		get { self[ImportLegacyWalletClient.self] }
		set { self[ImportLegacyWalletClient.self] = newValue }
	}
}

// MARK: - ImportLegacyWalletClient + TestDependencyKey
extension ImportLegacyWalletClient: TestDependencyKey {
	public static let previewValue = Self(
		shouldShowImportWalletShortcutInSettings: { false },
		parseHeaderFromQRCode: { _ in throw NoopError() },
		parseLegacyWalletFromQRCodes: { _ in throw NoopError() },
		migrateOlympiaSoftwareAccountsToBabylon: { _ in throw NoopError() },
		migrateOlympiaHardwareAccountsToBabylon: { _ in throw NoopError() },
		findAlreadyImportedIfAny: { _ in [] }
	)

	public static let testValue = Self(
		shouldShowImportWalletShortcutInSettings: unimplemented("\(Self.self).shouldShowImportWalletShortcutInSettings"),
		parseHeaderFromQRCode: unimplemented("\(Self.self).parseHeaderFromQRCode"),
		parseLegacyWalletFromQRCodes: unimplemented("\(Self.self).parseLegacyWalletFromQRCodes"),
		migrateOlympiaSoftwareAccountsToBabylon: unimplemented("\(Self.self).migrateOlympiaSoftwareAccountsToBabylon"),
		migrateOlympiaHardwareAccountsToBabylon: unimplemented("\(Self.self).migrateOlympiaHardwareAccountsToBabylon"),
		findAlreadyImportedIfAny: unimplemented("\(Self.self).findAlreadyImportedIfAny")
	)
}

// MARK: - ImportedOlympiaWalletFailedToFindAnyAccounts
struct ImportedOlympiaWalletFailedToFindAnyAccounts: Swift.Error {}

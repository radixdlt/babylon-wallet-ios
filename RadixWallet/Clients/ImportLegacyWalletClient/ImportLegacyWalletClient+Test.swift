
extension DependencyValues {
	var importLegacyWalletClient: ImportLegacyWalletClient {
		get { self[ImportLegacyWalletClient.self] }
		set { self[ImportLegacyWalletClient.self] = newValue }
	}
}

// MARK: - ImportLegacyWalletClient + TestDependencyKey
extension ImportLegacyWalletClient: TestDependencyKey {
	static let previewValue = Self.noop

	static let testValue = Self(
		shouldShowImportWalletShortcutInSettings: unimplemented("\(Self.self).shouldShowImportWalletShortcutInSettings", placeholder: noop.shouldShowImportWalletShortcutInSettings),
		parseHeaderFromQRCode: unimplemented("\(Self.self).parseHeaderFromQRCode"),
		parseLegacyWalletFromQRCodes: unimplemented("\(Self.self).parseLegacyWalletFromQRCodes"),
		migrateOlympiaSoftwareAccountsToBabylon: unimplemented("\(Self.self).migrateOlympiaSoftwareAccountsToBabylon"),
		migrateOlympiaHardwareAccountsToBabylon: unimplemented("\(Self.self).migrateOlympiaHardwareAccountsToBabylon"),
		findAlreadyImportedIfAny: unimplemented("\(Self.self).findAlreadyImportedIfAny", placeholder: noop.findAlreadyImportedIfAny)
	)

	static let noop = Self(
		shouldShowImportWalletShortcutInSettings: { false },
		parseHeaderFromQRCode: { _ in throw NoopError() },
		parseLegacyWalletFromQRCodes: { _ in throw NoopError() },
		migrateOlympiaSoftwareAccountsToBabylon: { _ in throw NoopError() },
		migrateOlympiaHardwareAccountsToBabylon: { _ in throw NoopError() },
		findAlreadyImportedIfAny: { _ in [] }
	)
}

// MARK: - ImportedOlympiaWalletFailedToFindAnyAccounts
struct ImportedOlympiaWalletFailedToFindAnyAccounts: Swift.Error {}

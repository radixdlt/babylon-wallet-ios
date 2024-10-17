// MARK: - ImportLegacyWalletClient
struct ImportLegacyWalletClient: Sendable {
	var shouldShowImportWalletShortcutInSettings: ShouldShowImportWalletShortcutInSettings
	var parseHeaderFromQRCode: ParseHeaderFromQRCode
	var parseLegacyWalletFromQRCodes: ParseLegacyWalletFromQRCodes

	var migrateOlympiaSoftwareAccountsToBabylon: MigrateOlympiaSoftwareAccountsToBabylon
	var migrateOlympiaHardwareAccountsToBabylon: MigrateOlympiaHardwareAccountsToBabylon

	var findAlreadyImportedIfAny: FindAlreadyImportedIfAny
}

extension ImportLegacyWalletClient {
	typealias ShouldShowImportWalletShortcutInSettings = @Sendable () async -> Bool
	typealias ParseHeaderFromQRCode = @Sendable (NonEmptyString) throws -> Olympia.Export.Payload.Header

	typealias ParseLegacyWalletFromQRCodes = @Sendable (_ qrCodes: NonEmpty<OrderedSet<NonEmptyString>>) throws -> ScannedParsedOlympiaWalletToMigrate

	typealias MigrateOlympiaSoftwareAccountsToBabylon = @Sendable (MigrateOlympiaSoftwareAccountsToBabylonRequest) async throws -> MigratedSoftwareAccounts

	typealias MigrateOlympiaHardwareAccountsToBabylon = @Sendable (MigrateOlympiaHardwareAccountsToBabylonRequest) async throws -> MigratedHardwareAccounts

	typealias FindAlreadyImportedIfAny = @Sendable (NonEmpty<OrderedSet<OlympiaAccountToMigrate>>) async -> Set<OlympiaAccountToMigrate.ID>
}

// extension ImportLegacyWalletClient {
//	// FIXME: Post mainnet remove this function, only used to allow DEBUG builds //	static func canImportOlympiaWallet(
//		currentNetworkID: NetworkID,
//		isDeveloperModeEnabled: Bool
//	) -> Bool {
//		networkIDForOlympiaAccountsToImportInto(
//			currentNetworkID: currentNetworkID,
//			isDeveloperModeEnabled: isDeveloperModeEnabled
//		) != nil
//	}
//
//	// FIXME: Post mainnet remove this function, only used to allow DEBUG builds //	/// Returns `nil` if it is not supported to //	static func networkIDForOlympiaAccountsToImportInto(
//		currentNetworkID: NetworkID,
//		isDeveloperModeEnabled: Bool
//	) -> NetworkID? {
//		guard currentNetworkID == .mainnet else {
//			#if DEBUG
//			if isDeveloperModeEnabled {
//				// ONLY for DEBUG builds where `isDeveloperModeEnabled` is set, we allow
//				// importing into non mainnet
//				return currentNetworkID
//			}
//			#endif
//
//			// Current network is not mainnet, return nil marking it is not possible to //			return nil
//		}
//		return .mainnet
//	}
// }

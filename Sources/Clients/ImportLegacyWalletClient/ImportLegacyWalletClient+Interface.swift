import ClientPrelude
import Profile

// MARK: - ImportLegacyWalletClient
public struct ImportLegacyWalletClient: Sendable {
	public var shouldShowImportWalletShortcutInSettings: ShouldShowImportWalletShortcutInSettings
	public var parseHeaderFromQRCode: ParseHeaderFromQRCode
	public var parseLegacyWalletFromQRCodes: ParseLegacyWalletFromQRCodes

	public var migrateOlympiaSoftwareAccountsToBabylon: MigrateOlympiaSoftwareAccountsToBabylon
	public var migrateOlympiaHardwareAccountsToBabylon: MigrateOlympiaHardwareAccountsToBabylon

	public var findAlreadyImportedIfAny: FindAlreadyImportedIfAny
}

extension ImportLegacyWalletClient {
	public typealias ShouldShowImportWalletShortcutInSettings = @Sendable () async -> Bool
	public typealias ParseHeaderFromQRCode = @Sendable (NonEmptyString) throws -> Olympia.Export.Payload.Header

	public typealias ParseLegacyWalletFromQRCodes = @Sendable (_ qrCodes: NonEmpty<OrderedSet<NonEmptyString>>) throws -> ScannedParsedOlympiaWalletToMigrate

	public typealias MigrateOlympiaSoftwareAccountsToBabylon = @Sendable (MigrateOlympiaSoftwareAccountsToBabylonRequest) async throws -> MigratedSoftwareAccounts

	public typealias MigrateOlympiaHardwareAccountsToBabylon = @Sendable (MigrateOlympiaHardwareAccountsToBabylonRequest) async throws -> MigratedHardwareAccounts

	public typealias FindAlreadyImportedIfAny = @Sendable (NonEmpty<OrderedSet<OlympiaAccountToMigrate>>) async -> Set<OlympiaAccountToMigrate.ID>
}

import EngineKit

// extension ImportLegacyWalletClient {
//	// FIXME: Post mainnet remove this function, only used to allow DEBUG builds import Olympia wallets
//	public static func canImportOlympiaWallet(
//		currentNetworkID: NetworkID,
//		isDeveloperModeEnabled: Bool
//	) -> Bool {
//		networkIDForOlympiaAccountsToImportInto(
//			currentNetworkID: currentNetworkID,
//			isDeveloperModeEnabled: isDeveloperModeEnabled
//		) != nil
//	}
//
//	// FIXME: Post mainnet remove this function, only used to allow DEBUG builds import Olympia wallets
//	/// Returns `nil` if it is not supported to import olympia accounts at all, given the input
//	public static func networkIDForOlympiaAccountsToImportInto(
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
//			// Current network is not mainnet, return nil marking it is not possible to import olympia accounts into non mainnet network
//			return nil
//		}
//		return .mainnet
//	}
// }

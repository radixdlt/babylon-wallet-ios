import ClientPrelude
import Profile

// MARK: - ImportLegacyWalletClient
public struct ImportLegacyWalletClient: Sendable {
	public var parseHeaderFromQRCode: ParseHeaderFromQRCode
	public var parseLegacyWalletFromQRCodes: ParseLegacyWalletFromQRCodes

	public var migrateOlympiaSoftwareAccountsToBabylon: MigrateOlympiaSoftwareAccountsToBabylon
	public var migrateOlympiaHardwareAccountsToBabylon: MigrateOlympiaHardwareAccountsToBabylon
}

extension ImportLegacyWalletClient {
	public typealias ParseHeaderFromQRCode = @Sendable (NonEmptyString) throws -> Olympia.Export.Payload.Header

	public typealias ParseLegacyWalletFromQRCodes = @Sendable (_ qrCodes: NonEmpty<OrderedSet<NonEmptyString>>) throws -> ScannedParsedOlympiaWalletToMigrate

	public typealias MigrateOlympiaSoftwareAccountsToBabylon = @Sendable (MigrateOlympiaSoftwareAccountsToBabylonRequest) async throws -> MigratedSoftwareAccounts

	public typealias MigrateOlympiaHardwareAccountsToBabylon = @Sendable (MigrateOlympiaHardwareAccountsToBabylonRequest) async throws -> MigratedHardwareAccounts
}

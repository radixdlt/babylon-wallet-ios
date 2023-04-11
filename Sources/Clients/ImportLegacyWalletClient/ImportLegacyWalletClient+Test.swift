import ClientPrelude
import Cryptography
import Profile

extension DependencyValues {
	public var importLegacyWalletClient: ImportLegacyWalletClient {
		get { self[ImportLegacyWalletClient.self] }
		set { self[ImportLegacyWalletClient.self] = newValue }
	}
}

// MARK: - ImportLegacyWalletClient + TestDependencyKey
extension ImportLegacyWalletClient: TestDependencyKey {
	public static let previewValue = Self(
		parseHeaderFromQRCode: { _ in throw NoopError() },
		parseLegacyWalletFromQRCodes: { _ in throw NoopError() },
		migrateOlympiaSoftwareAccountsToBabylon: { _ in throw NoopError() },
		migrateOlympiaHardwareAccountsToBabylon: { _ in throw NoopError() }
	)

	public static let testValue = Self(
		parseHeaderFromQRCode: unimplemented("\(Self.self).parseHeaderFromQRCode"),
		parseLegacyWalletFromQRCodes: unimplemented("\(Self.self).parseLegacyWalletFromQRCodes"),
		migrateOlympiaSoftwareAccountsToBabylon: unimplemented("\(Self.self).migrateOlympiaSoftwareAccountsToBabylon"),
		migrateOlympiaHardwareAccountsToBabylon: unimplemented("\(Self.self).migrateOlympiaHardwareAccountsToBabylon")
	)
}

// MARK: - ImportedOlympiaWalletFailedToFindAnyAccounts
struct ImportedOlympiaWalletFailedToFindAnyAccounts: Swift.Error {}

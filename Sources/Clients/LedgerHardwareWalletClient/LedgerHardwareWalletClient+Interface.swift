import ClientPrelude
import Profile

// MARK: - LedgerHardwareWalletClient
public struct LedgerHardwareWalletClient: Sendable {
	public var getDeviceInfo: GetDeviceInfo
	public var importOlympiaDevice: ImportOlympiaDevice
}

extension LedgerHardwareWalletClient {
	public typealias ImportOlympiaDevice = @Sendable (Set<OlympiaAccountToMigrate>) async throws -> P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.ImportOlympiaDevice
	public typealias GetDeviceInfo = @Sendable () async throws -> P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.GetDeviceInfo
}

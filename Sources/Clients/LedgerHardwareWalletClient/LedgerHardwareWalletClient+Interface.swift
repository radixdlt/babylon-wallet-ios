import ClientPrelude
import Cryptography
import Profile

// MARK: - LedgerHardwareWalletClient
public struct LedgerHardwareWalletClient: Sendable {
	public var isConnectedToAnyConnectorExtension: IsConnectedToAnyConnectorExtension
	public var getDeviceInfo: GetDeviceInfo
	public var importOlympiaDevice: ImportOlympiaDevice
	public var deriveCurve25519PublicKey: DeriveCurve25519PublicKey
}

extension LedgerHardwareWalletClient {
	public typealias IsConnectedToAnyConnectorExtension = @Sendable () async -> AnyAsyncSequence<Bool>
	public typealias ImportOlympiaDevice = @Sendable (Set<OlympiaAccountToMigrate>) async throws -> P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.ImportOlympiaDevice
	public typealias GetDeviceInfo = @Sendable () async throws -> P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.GetDeviceInfo
	public typealias DeriveCurve25519PublicKey = @Sendable (DerivationPath, FactorSource) async throws -> Curve25519.Signing.PublicKey
}

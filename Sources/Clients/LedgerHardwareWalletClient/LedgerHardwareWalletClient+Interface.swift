import ClientPrelude
import Cryptography
import FactorSourcesClient
import Profile

// MARK: - LedgerHardwareWalletClient
public struct LedgerHardwareWalletClient: Sendable {
	public var isConnectedToAnyConnectorExtension: IsConnectedToAnyConnectorExtension
	public var getDeviceInfo: GetDeviceInfo
	public var importOlympiaDevice: ImportOlympiaDevice
	public var deriveCurve25519PublicKey: DeriveCurve25519PublicKey
	public var sign: Sign
}

extension LedgerHardwareWalletClient {
	public typealias IsConnectedToAnyConnectorExtension = @Sendable () async -> AnyAsyncSequence<Bool>
	public typealias ImportOlympiaDevice = @Sendable (Set<OlympiaAccountToMigrate>) async throws -> P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.ImportOlympiaDevice
	public typealias GetDeviceInfo = @Sendable () async throws -> P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.GetDeviceInfo
	public typealias DeriveCurve25519PublicKey = @Sendable (DerivationPath, FactorSource) async throws -> Curve25519.Signing.PublicKey
	public typealias Sign = @Sendable (SignWithLedgerRequest) async throws -> Set<AccountSignature>
}

// MARK: - SignWithLedgerRequest
public struct SignWithLedgerRequest: Sendable, Hashable {
	public let signingFactor: SigningFactor
	public let unhashedDataToSign: Data
	public let ledgerTXDisplayMode: P2P.ConnectorExtension.Request.LedgerHardwareWallet.Request.SignTransaction.Mode
	public let displayHashOnLedgerDisplay: Bool

	public init(
		signingFactor: SigningFactor,
		unhashedDataToSign: Data,
		ledgerTXDisplayMode: P2P.ConnectorExtension.Request.LedgerHardwareWallet.Request.SignTransaction.Mode,
		displayHashOnLedgerDisplay: Bool
	) {
		precondition(signingFactor.factorSource.kind == .ledgerHQHardwareWallet)
		self.signingFactor = signingFactor
		self.unhashedDataToSign = unhashedDataToSign
		self.ledgerTXDisplayMode = ledgerTXDisplayMode
		self.displayHashOnLedgerDisplay = displayHashOnLedgerDisplay
	}
}

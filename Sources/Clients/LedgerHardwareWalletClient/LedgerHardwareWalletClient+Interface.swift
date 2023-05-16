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
	public var signTransaction: SignTransaction
	public var signAuthChallenge: SignAuthChallenge
}

extension LedgerHardwareWalletClient {
	public typealias IsConnectedToAnyConnectorExtension = @Sendable () async -> AnyAsyncSequence<Bool>
	public typealias ImportOlympiaDevice = @Sendable (Set<OlympiaAccountToMigrate>) async throws -> P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.ImportOlympiaDevice
	public typealias GetDeviceInfo = @Sendable () async throws -> P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.GetDeviceInfo
	public typealias DeriveCurve25519PublicKey = @Sendable (DerivationPath, FactorSource) async throws -> Curve25519.Signing.PublicKey
	public typealias SignTransaction = @Sendable (SignTransactionWithLedgerRequest) async throws -> Set<SignatureOfEntity>
	public typealias SignAuthChallenge = @Sendable (SignAuthChallengeWithLedgerRequest) async throws -> Set<SignatureOfEntity>
}

// MARK: - SignTransactionWithLedgerRequest
public struct SignTransactionWithLedgerRequest: Sendable, Hashable {
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

// MARK: - SignAuthChallengeWithLedgerRequest
public struct SignAuthChallengeWithLedgerRequest: Sendable, Hashable {
	public let signingFactor: SigningFactor
	public let challenge: P2P.Dapp.Request.AuthChallengeNonce
	public let origin: P2P.Dapp.Request.Metadata.Origin
	public let dAppDefinitionAddress: AccountAddress

	public init(
		signingFactor: SigningFactor,
		challenge: P2P.Dapp.Request.AuthChallengeNonce,
		origin: P2P.Dapp.Request.Metadata.Origin,
		dAppDefinitionAddress: AccountAddress
	) {
		precondition(signingFactor.factorSource.kind == .ledgerHQHardwareWallet)
		self.signingFactor = signingFactor
		self.challenge = challenge
		self.origin = origin
		self.dAppDefinitionAddress = dAppDefinitionAddress
	}
}

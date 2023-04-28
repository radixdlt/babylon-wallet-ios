import ClientPrelude
import Cryptography
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
	public let ledger: FactorSource
	public let accounts: Set<Profile.Network.Account>
	public let unhashedDataToSign: Data

	public init(ledger: FactorSource, accounts: Set<Profile.Network.Account>, unhashedDataToSign: Data) {
		precondition(ledger.kind == .ledgerHQHardwareWallet)
		self.ledger = ledger
		self.accounts = accounts
		self.unhashedDataToSign = unhashedDataToSign
	}
}

extension LedgerHardwareWalletClient {
	public func sign(
		ledger: FactorSource,
		signers: Set<Profile.Network.Account>,
		unhashedDataToSign: Data
	) async throws -> Set<AccountSignature> {
		precondition(ledger.kind == .ledgerHQHardwareWallet)
		return try await sign(.init(
			ledger: ledger,
			accounts: signers,
			unhashedDataToSign: unhashedDataToSign
		))
	}
}

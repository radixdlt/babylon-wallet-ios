import ClientPrelude
import Cryptography
import FactorSourcesClient
import Profile

// MARK: - LedgerHardwareWalletClient
public struct LedgerHardwareWalletClient: Sendable {
	public var isConnectedToAnyConnectorExtension: IsConnectedToAnyConnectorExtension
	public var getDeviceInfo: GetDeviceInfo
	public var derivePublicKeys: DerivePublicKeys
	public var signTransaction: SignTransaction
	public var signAuthChallenge: SignAuthChallenge
}

extension LedgerHardwareWalletClient {
	public typealias IsConnectedToAnyConnectorExtension = @Sendable () async -> AnyAsyncSequence<Bool>
	public typealias GetDeviceInfo = @Sendable () async throws -> P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.GetDeviceInfo
	public typealias DerivePublicKeys = @Sendable (OrderedSet<P2P.LedgerHardwareWallet.KeyParameters>, LedgerHardwareWalletFactorSource) async throws -> OrderedSet<HierarchicalDeterministicPublicKey>
	public typealias SignTransaction = @Sendable (SignTransactionWithLedgerRequest) async throws -> Set<SignatureOfEntity>
	public typealias SignAuthChallenge = @Sendable (SignAuthChallengeWithLedgerRequest) async throws -> Set<SignatureOfEntity>
}

// MARK: - SignTransactionWithLedgerRequest
public struct SignTransactionWithLedgerRequest: Sendable, Hashable {
	public let signers: NonEmpty<IdentifiedArrayOf<Signer>>
	public let ledger: LedgerHardwareWalletFactorSource
	public let hashedDataToSign: HashedData
	public let ledgerTXDisplayMode: P2P.ConnectorExtension.Request.LedgerHardwareWallet.Request.SignTransaction.Mode
	public let displayHashOnLedgerDisplay: Bool

	public init(
		ledger: LedgerHardwareWalletFactorSource,
		signers: NonEmpty<IdentifiedArrayOf<Signer>>,
		hashedDataToSign: HashedData,
		ledgerTXDisplayMode: P2P.ConnectorExtension.Request.LedgerHardwareWallet.Request.SignTransaction.Mode,
		displayHashOnLedgerDisplay: Bool
	) {
		self.signers = signers
		self.ledger = ledger
		self.hashedDataToSign = hashedDataToSign
		self.ledgerTXDisplayMode = ledgerTXDisplayMode
		self.displayHashOnLedgerDisplay = displayHashOnLedgerDisplay
	}
}

// MARK: - SignAuthChallengeWithLedgerRequest
public struct SignAuthChallengeWithLedgerRequest: Sendable, Hashable {
	public let signers: NonEmpty<IdentifiedArrayOf<Signer>>
	public let ledger: LedgerHardwareWalletFactorSource
	public let challenge: P2P.Dapp.Request.AuthChallengeNonce
	public let origin: P2P.Dapp.Request.Metadata.Origin
	public let dAppDefinitionAddress: AccountAddress

	public init(
		ledger: LedgerHardwareWalletFactorSource,
		signers: NonEmpty<IdentifiedArrayOf<Signer>>,
		challenge: P2P.Dapp.Request.AuthChallengeNonce,
		origin: P2P.Dapp.Request.Metadata.Origin,
		dAppDefinitionAddress: AccountAddress
	) {
		self.ledger = ledger
		self.signers = signers
		self.challenge = challenge
		self.origin = origin
		self.dAppDefinitionAddress = dAppDefinitionAddress
	}
}

// MARK: - LedgerHardwareWalletClient
public struct LedgerHardwareWalletClient: Sendable {
	public var isConnectedToAnyConnectorExtension: IsConnectedToAnyConnectorExtension
	public var getDeviceInfo: GetDeviceInfo
	public var derivePublicKeys: DerivePublicKeys
	public var signTransaction: SignTransaction
	public var signAuthChallenge: SignAuthChallenge
	public var deriveAndDisplayAddress: DeriveAndDisplayAddress
}

extension LedgerHardwareWalletClient {
	public typealias IsConnectedToAnyConnectorExtension = @Sendable () async -> AnyAsyncSequence<Bool>
	public typealias GetDeviceInfo = @Sendable () async throws -> P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.GetDeviceInfo
	public typealias DerivePublicKeys = @Sendable ([P2P.LedgerHardwareWallet.KeyParameters], LedgerHardwareWalletFactorSource) async throws -> [HierarchicalDeterministicPublicKey]

	public typealias DeriveAndDisplayAddress = @Sendable (P2P.LedgerHardwareWallet.KeyParameters, LedgerHardwareWalletFactorSource) async throws -> (HierarchicalDeterministicPublicKey, String)

	public typealias SignTransaction = @Sendable (SignTransactionWithLedgerRequest) async throws -> Set<SignatureOfEntity>
	public typealias SignAuthChallenge = @Sendable (SignAuthChallengeWithLedgerRequest) async throws -> Set<SignatureOfEntity>
}

// MARK: - VerifyAddressOutcome
public enum VerifyAddressOutcome: Sendable, Hashable {
	public enum Mismatch: Sendable, Hashable {
		case publicKeyMismatch
		case addressMismatch
	}

	/// Either addresses do not match, or public key do not match.
	case mismatch(Mismatch)
	case verifiedSame
}

// MARK: - SignTransactionWithLedgerRequest
public struct SignTransactionWithLedgerRequest: Sendable, Hashable {
	public let signers: NonEmpty<IdentifiedArrayOf<Signer>>
	public let ledger: LedgerHardwareWalletFactorSource
	public let transactionIntent: TransactionIntent
	public let displayHashOnLedgerDisplay: Bool

	public init(
		ledger: LedgerHardwareWalletFactorSource,
		signers: NonEmpty<IdentifiedArrayOf<Signer>>,
		transactionIntent: TransactionIntent,
		displayHashOnLedgerDisplay: Bool
	) {
		self.signers = signers
		self.ledger = ledger
		self.transactionIntent = transactionIntent
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

// MARK: - FailedToFindLedger
struct FailedToFindLedger: LocalizedError {
	let factorSourceID: FactorSourceID
	var errorDescription: String? {
		#if DEBUG
		"Failed to find ledger with ID: \(factorSourceID)"
		#else
		L10n.Error.TransactionFailure.failedToFindLedger
		#endif
	}
}

extension LedgerHardwareWalletClient {
	public func verifyAddress(of accountAddress: AccountAddress) {
		@Dependency(\.accountsClient) var accountsClient
		@Dependency(\.overlayWindowClient) var overlayWindowClient
		Task {
			do {
				let account = try await accountsClient.getAccountByAddress(accountAddress)
				let outcome = try await verifyAddress(of: account)

				switch outcome {
				case .verifiedSame:
					overlayWindowClient.scheduleHUD(.init(
						text: L10n.LedgerHardwareDevices.Verification.addressVerified,
						icon: .init(
							kind: .system("checkmark.seal.fill"),
							foregroundColor: Color.app.green1
						)
					))

				case let .mismatch(discrepancy):
					let reason = switch discrepancy {
					case .addressMismatch:
						L10n.LedgerHardwareDevices.Verification.mismatch
					case .publicKeyMismatch:
						L10n.LedgerHardwareDevices.Verification.badResponse
					}
					loggerGlobal.critical("Discrepancy invalid ledger account, reason: \(reason)")
					overlayWindowClient.scheduleHUD(.init(
						text: reason,
						icon: .init(
							kind: .asset(AssetResource.error),
							foregroundColor: Color.app.red1
						)
					))
				}

			} catch {
				loggerGlobal.error("Verify address request failed, error: \(error)")
				overlayWindowClient.scheduleHUD(.init(
					text: L10n.LedgerHardwareDevices.Verification.requestFailed,
					icon: .init(
						kind: .asset(AssetResource.error),
						foregroundColor: Color.app.red1
					)
				))
			}
		}
	}

	@discardableResult
	public func verifyAddress(of account: Profile.Network.Account) async throws -> VerifyAddressOutcome {
		@Dependency(\.factorSourcesClient) var factorSourcesClient
		switch account.securityState {
		case let .unsecured(unsecuredEntityControl):
			let signTXFactorInstance = unsecuredEntityControl.transactionSigning
			let factorSourceID = signTXFactorInstance.factorSourceID.embed()
			guard let ledger = try await factorSourcesClient.getFactorSource(
				id: factorSourceID,
				as: LedgerHardwareWalletFactorSource.self
			) else {
				throw FailedToFindLedger(factorSourceID: factorSourceID)
			}
			let keyParams = P2P.LedgerHardwareWallet.KeyParameters(
				curve: signTXFactorInstance.derivationPath.curveForScheme.toLedger(),
				derivationPath: signTXFactorInstance.derivationPath.path
			)

			let (derivedKey, address) = try await deriveAndDisplayAddress(keyParams, ledger)

			if derivedKey != signTXFactorInstance.hierarchicalDeterministicPublicKey {
				let errMsg = "Re-derived public key on Ledger does not matched the transactionSigning factor instance of the account. \(derivedKey) != \(signTXFactorInstance.hierarchicalDeterministicPublicKey)"
				loggerGlobal.error(.init(stringLiteral: errMsg))
				return .mismatch(.publicKeyMismatch)
			}

			if address != account.address.address {
				let errMsg = "Re-derived EngineToolkitAddress on Ledger does not matched the account. \(address) != \(account.address.address)"
				loggerGlobal.error(.init(stringLiteral: errMsg))
				return .mismatch(.addressMismatch)
			}

			return .verifiedSame
		}
	}
}

extension SLIP10.Curve {
	public func toLedger() -> P2P.LedgerHardwareWallet.KeyParameters.Curve {
		switch self {
		case .curve25519: .curve25519
		case .secp256k1: .secp256k1
		}
	}
}

extension P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.DerivedPublicKey {
	public func hdPubKey() throws -> HierarchicalDeterministicPublicKey {
		try .init(curve: self.curve, key: self.publicKey.data, path: self.derivationPath)
	}
}

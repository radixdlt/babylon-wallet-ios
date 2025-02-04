import Sargon

// MARK: - LedgerHardwareWalletClient
struct LedgerHardwareWalletClient: Sendable {
	var isConnectedToAnyConnectorExtension: IsConnectedToAnyConnectorExtension
	var getDeviceInfo: GetDeviceInfo
	var derivePublicKeys: DerivePublicKeys
	var signTransaction: SignTransaction
	var signSubintent: SignSubintent
	var signAuth: SignAuth
	var deriveAndDisplayAddress: DeriveAndDisplayAddress
}

extension LedgerHardwareWalletClient {
	typealias IsConnectedToAnyConnectorExtension = @Sendable () async -> AnyAsyncSequence<Bool>
	typealias GetDeviceInfo = @Sendable () async throws -> P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.GetDeviceInfo
	typealias DerivePublicKeys = @Sendable (DerivePublicKeysRequest) async throws -> [HierarchicalDeterministicFactorInstance]

	typealias DeriveAndDisplayAddress = @Sendable (P2P.LedgerHardwareWallet.KeyParameters, LedgerHardwareWalletFactorSource) async throws -> (HierarchicalDeterministicPublicKey, String)

	typealias SignTransaction = @Sendable (SignTransactionRequest) async throws -> Set<HdSignatureOfTransactionIntentHash>
	typealias SignSubintent = @Sendable (SignSubintentRequest) async throws -> Set<HdSignatureOfSubintentHash>
	typealias SignAuth = @Sendable (SignAuthRequest) async throws -> Set<HdSignatureOfAuthIntentHash>
}

// MARK: LedgerHardwareWalletClient.NewSignTransactionRequest
extension LedgerHardwareWalletClient {
	struct DerivePublicKeysRequest: Sendable, Hashable {
		let ledger: LedgerHardwareWalletFactorSource
		let input: KeyDerivationRequestPerFactorSource
	}

	struct SignTransactionRequest: Sendable, Hashable {
		let ledger: LedgerHardwareWalletFactorSource
		let input: TransactionSignRequestInputOfTransactionIntent
	}

	struct SignSubintentRequest: Sendable, Hashable {
		let ledger: LedgerHardwareWalletFactorSource
		let input: TransactionSignRequestInputOfSubintent
	}

	struct SignAuthRequest: Sendable, Hashable {
		let ledger: LedgerHardwareWalletFactorSource
		let input: TransactionSignRequestInputOfAuthIntent
	}
}

// MARK: - VerifyAddressOutcome
enum VerifyAddressOutcome: Sendable, Hashable {
	enum Mismatch: Sendable, Hashable {
		case publicKeyMismatch
		case addressMismatch
	}

	/// Either addresses do not match, or key do not match.
	case mismatch(Mismatch)
	case verifiedSame
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
	func verifyAddress(of accountAddress: AccountAddress) {
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
	func verifyAddress(of account: Account) async throws -> VerifyAddressOutcome {
		@Dependency(\.factorSourcesClient) var factorSourcesClient
		switch account.securityState {
		case let .unsecured(unsecuredEntityControl):
			let signTXFactorInstance = unsecuredEntityControl.transactionSigning
			let factorSourceID = signTXFactorInstance.factorSourceID.asGeneral
			guard let ledger = try await factorSourcesClient.getFactorSource(
				id: factorSourceID,
				as: LedgerHardwareWalletFactorSource.self
			) else {
				throw FailedToFindLedger(factorSourceID: factorSourceID)
			}
			let keyParams = P2P.LedgerHardwareWallet.KeyParameters(
				curve: signTXFactorInstance.derivationPath.curve.toLedger(),
				derivationPath: signTXFactorInstance.derivationPath.toString()
			)

			let (derivedKey, address) = try await deriveAndDisplayAddress(keyParams, ledger)

			if derivedKey != signTXFactorInstance.publicKey {
				let errMsg = "Re-derived key on Ledger does not matched the transactionSigning factor instance of the account. \(derivedKey) != \(signTXFactorInstance.publicKey)"
				loggerGlobal.error(.init(stringLiteral: errMsg))
				return .mismatch(.publicKeyMismatch)
			}

			if address != account.address.address {
				let errMsg = "Re-derived Address on Ledger does not matched the account. \(address) != \(account.address.address)"
				loggerGlobal.error(.init(stringLiteral: errMsg))
				return .mismatch(.addressMismatch)
			}

			return .verifiedSame
		}
	}
}

extension SLIP10Curve {
	func toLedger() -> P2P.LedgerHardwareWallet.KeyParameters.Curve {
		switch self {
		case .curve25519: .curve25519
		case .secp256k1: .secp256k1
		}
	}
}

extension P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.DerivedPublicKey {
	func hdPubKey() throws -> HierarchicalDeterministicPublicKey {
		try .init(curve: self.curve, key: self.publicKey.data, path: self.derivationPath)
	}
}

import AccountPortfolio
import ClientPrelude
import Cryptography
import EngineToolkitClient
import GatewayAPI
import ProfileClient
import Resources
import UseFactorSourceClient

extension TransactionClient {
	public static var liveValue: Self {
		@Dependency(\.engineToolkitClient) var engineToolkitClient
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.keychainClient) var keychainClient
		@Dependency(\.profileClient) var profileClient
		@Dependency(\.accountPortfolioFetcher) var accountPortfolioFetcher
		@Dependency(\.useFactorSourceClient) var useFactorSourceClient

		let pollStrategy: PollStrategy = .default

		@Sendable
		func compileAndSign(
			transactionIntent: TransactionIntent,
			notaryAndSigners: NotaryAndSigners
		) async -> Result<(txID: TXID, compiledNotarizedTXIntent: CompileNotarizedTransactionIntentResponse), TransactionFailure.CompileOrSignFailure> {
			let compiledTransactionIntent: CompileTransactionIntentResponse
			do {
				compiledTransactionIntent = try engineToolkitClient.compileTransactionIntent(transactionIntent)
			} catch {
				return .failure(.failedToCompileTXIntent)
			}

			let txID: TXID
			do {
				txID = try engineToolkitClient.generateTXID(transactionIntent)
			} catch {
				return .failure(.failedToGenerateTXId)
			}

			let factorSource = try! await profileClient.getFactorSources().first(where: { $0.kind == .device })!
			let factorSourceID = factorSource.id
			guard let loadedMnemonicWithPassphrase = try! await keychainClient.loadFactorSourceMnemonicWithPassphrase(
				factorSourceID: factorSourceID,
				authenticationPrompt: L10n.TransactionSigning.biometricsPrompt
			) else {
				fatalError("should not happend")
			}
			let hdRoot = try! loadedMnemonicWithPassphrase.hdRoot()

			@Sendable func sign(data: any DataProtocol, with account: OnNetwork.Account) async throws -> SignatureWithPublicKey {
				switch account.securityState {
				case let .unsecured(unsecuredControl):
					let factorInstance = unsecuredControl.genesisFactorInstance
					guard factorInstance.factorSourceID == factorSourceID else {
						fatalError("wrong signer.")
					}
					let sigRes: SignatureWithPublicKey = try useFactorSourceClient.signatureFromOnDeviceHD(.init(
						hdRoot: hdRoot,
						derivationPath: factorInstance.derivationPath!,
						curve: factorSource.parameters.supportedCurves.first,
						data: Data(data)
					))
					return sigRes
				}
			}

			let intentSignatures_: [SignatureWithPublicKey]
			do {
				intentSignatures_ = try await notaryAndSigners.accountsNeededToSign.asyncMap {
					try await sign(data: compiledTransactionIntent.compiledIntent, with: $0)
				}
			} catch {
				return .failure(.failedToSignIntentWithAccountSigners)
			}

			let intentSignatures: [Engine.SignatureWithPublicKey]
			do {
				intentSignatures = try intentSignatures_.map { try $0.intoEngine() }
			} catch {
				return .failure(.failedToConvertAccountSignatures)
			}

			let signedTransactionIntent = SignedTransactionIntent(
				intent: transactionIntent,
				intentSignatures: intentSignatures
			)
			let compiledSignedIntent: CompileSignedTransactionIntentResponse
			do {
				compiledSignedIntent = try engineToolkitClient.compileSignedTransactionIntent(signedTransactionIntent)
			} catch {
				return .failure(.failedToCompileSignedTXIntent)
			}

			let notarySignatureWithPublicKey: SignatureWithPublicKey
			do {
				notarySignatureWithPublicKey = try await sign(data: compiledSignedIntent.compiledIntent, with: notaryAndSigners.notarySigner)
			} catch {
				return .failure(.failedToSignSignedCompiledIntentWithNotarySigner)
			}

			let notarySignature: Engine.Signature
			do {
				notarySignature = try notarySignatureWithPublicKey.intoEngine().signature
			} catch {
				return .failure(.failedToConvertNotarySignature)
			}
			let uncompiledNotarized = NotarizedTransaction(
				signedIntent: signedTransactionIntent,
				notarySignature: notarySignature
			)
			let compiledNotarizedTXIntent: CompileNotarizedTransactionIntentResponse
			do {
				compiledNotarizedTXIntent = try engineToolkitClient.compileNotarizedTransactionIntent(uncompiledNotarized)
			} catch {
				return .failure(.failedToCompileNotarizedTXIntent)
			}

			return .success((txID: txID, compiledNotarizedTXIntent: compiledNotarizedTXIntent))
		}

		@Sendable
		func submitNotarizedTX(
			id txID: TXID, compiledNotarizedTXIntent: CompileNotarizedTransactionIntentResponse
		) async -> Result<TXID, SubmitTXFailure> {
			@Dependency(\.mainQueue) var mainQueue

			// MARK: Submit TX

			let submitTransactionRequest = GatewayAPI.TransactionSubmitRequest(
				notarizedTransactionHex: Data(compiledNotarizedTXIntent.compiledIntent).hex
			)

			let response: GatewayAPI.TransactionSubmitResponse

			do {
				response = try await gatewayAPIClient.submitTransaction(submitTransactionRequest)
			} catch {
				return .failure(.failedToSubmitTX)
			}

			guard !response.duplicate else {
				return .failure(.invalidTXWasDuplicate(txID: txID))
			}

			// MARK: Poll Status

			var txStatus: GatewayAPI.TransactionStatus = .pending

			@Sendable func pollTransactionStatus() async throws -> GatewayAPI.TransactionStatus {
				let txStatusRequest = GatewayAPI.TransactionStatusRequest(
					intentHashHex: txID.rawValue
				)
				let txStatusResponse = try await gatewayAPIClient.transactionStatus(txStatusRequest)
				return txStatusResponse.status
			}

			var pollCount = 0
			while !txStatus.isComplete {
				defer { pollCount += 1 }
				try? await mainQueue.sleep(for: .seconds(pollStrategy.sleepDuration))

				do {
					txStatus = try await pollTransactionStatus()
				} catch {
					// FIXME: - mainnet: improve handling of polling failure, should probably not return failure..
					return .failure(.failedToPollTX(txID: txID, error: .init(error: error)))
				}

				if pollCount >= pollStrategy.maxPollTries {
					return .failure(.failedToGetTransactionStatus(txID: txID, error: .init(pollAttempts: pollCount)))
				}
			}
			guard txStatus == .committedSuccess else {
				return .failure(.invalidTXWasSubmittedButNotSuccessful(txID: txID, status: txStatus == .rejected ? .rejected : .failed))
			}

			return .success(txID)
		}

		@Sendable
		func signAndSubmit(
			transactionIntent: TransactionIntent,
			notaryAndSigners: NotaryAndSigners
		) async -> TransactionResult {
			await compileAndSign(transactionIntent: transactionIntent, notaryAndSigners: notaryAndSigners)
				.mapError { TransactionFailure.failedToCompileOrSign($0) }
				.asyncFlatMap { (txID: TXID, compiledNotarizedTXIntent: CompileNotarizedTransactionIntentResponse) in
					await submitNotarizedTX(id: txID, compiledNotarizedTXIntent: compiledNotarizedTXIntent).mapError {
						TransactionFailure.failedToSubmit($0)
					}
				}
		}

		@Sendable
		func buildTransactionIntent(
			networkID: NetworkID,
			manifest: TransactionManifest,
			makeTransactionHeaderInput: MakeTransactionHeaderInput,
			getNotaryAndSigners: @Sendable (AccountAddressesInvolvedInTransactionRequest) async throws -> NotaryAndSigners
		) async -> Result<(intent: TransactionIntent, notaryAndSigners: NotaryAndSigners), TransactionFailure.FailedToPrepareForTXSigning> {
			let nonce = engineToolkitClient.generateTXNonce()
			let epoch: Epoch
			do {
				epoch = try await gatewayAPIClient.getEpoch()
			} catch {
				return .failure(.failedToGetEpoch)
			}

			let version = engineToolkitClient.getTransactionVersion()

			let accountAddressesNeedingToSignTransactionRequest = AccountAddressesInvolvedInTransactionRequest(
				version: version,
				manifest: manifest,
				networkID: networkID
			)

			let notaryAndSigners: NotaryAndSigners
			do {
				notaryAndSigners = try await getNotaryAndSigners(accountAddressesNeedingToSignTransactionRequest)
			} catch {
				return .failure(.failedToLoadNotaryAndSigners)
			}
			let notaryPublicKey: Engine.PublicKey
			do {
				let notarySigner = notaryAndSigners.notarySigner
				switch notarySigner.securityState {
				case let .unsecured(unsecuredControl):
					notaryPublicKey = unsecuredControl.genesisFactorInstance.publicKey
				default:
					// `TransactionClient` is going to be completely rewritten for multifactor support
					fixMultifactor()
				}
			} catch {
				return .failure(.failedToLoadNotaryPublicKey)
			}

			let header = TransactionHeader(
				version: version,
				networkId: networkID,
				startEpochInclusive: epoch,
				endEpochExclusive: epoch + makeTransactionHeaderInput.epochWindow,
				nonce: nonce,
				publicKey: notaryPublicKey,
				notaryAsSignatory: false,
				costUnitLimit: makeTransactionHeaderInput.costUnitLimit,
				tipPercentage: makeTransactionHeaderInput.tipPercentage
			)

			let intent = TransactionIntent(
				header: header,
				manifest: manifest
			)

			return .success((intent, notaryAndSigners))
		}

		@Sendable
		func signAndSubmit(
			manifest: TransactionManifest,
			makeTransactionHeaderInput: MakeTransactionHeaderInput,
			getNotaryAndSigners: @escaping @Sendable (AccountAddressesInvolvedInTransactionRequest) async throws -> NotaryAndSigners
		) async -> TransactionResult {
			await buildTransactionIntent(
				networkID: profileClient.getCurrentNetworkID(),
				manifest: manifest,
				makeTransactionHeaderInput: makeTransactionHeaderInput,
				getNotaryAndSigners: getNotaryAndSigners
			).mapError {
				TransactionFailure.failedToPrepareForTXSigning($0)
			}.asyncFlatMap { intent, notaryAndSigners in
				await signAndSubmit(transactionIntent: intent, notaryAndSigners: notaryAndSigners)
			}
		}

		let signAndSubmitTransaction: SignAndSubmitTransaction = { @Sendable request in
			await signAndSubmit(
				manifest: request.manifestToSign,
				makeTransactionHeaderInput: request.makeTransactionHeaderInput
			) { accountAddressesNeedingToSignTransactionRequest in

				// Might be empty
				let addressesNeededToSign = try OrderedSet(
					engineToolkitClient
						.accountAddressesNeedingToSignTransaction(
							accountAddressesNeedingToSignTransactionRequest
						)
				)

				let accountsNeededToSign: NonEmpty<OrderedSet<OnNetwork.Account>> = try await {
					let accounts = try await addressesNeededToSign.asyncMap {
						try await profileClient.lookupAccountByAddress($0)
					}
					guard let accounts = NonEmpty(rawValue: OrderedSet(uncheckedUniqueElements: accounts)) else {
						// TransactionManifest does not reference any accounts => use any account!
						let first = try await profileClient.getAccountsOnNetwork(accountAddressesNeedingToSignTransactionRequest.networkID).first
						return NonEmpty(rawValue: OrderedSet(uncheckedUniqueElements: [first]))!
					}
					return accounts
				}()

				let notary = await request.selectNotary(accountsNeededToSign)

				return .init(notarySigner: notary, accountsNeededToSign: accountsNeededToSign)
			}
		}

		let convertManifestInstructionsToJSONIfItWasString: ConvertManifestInstructionsToJSONIfItWasString = { manifest in
			let version = engineToolkitClient.getTransactionVersion()
			let networkID = await profileClient.getCurrentNetworkID()

			let conversionRequest = ConvertManifestInstructionsToJSONIfItWasStringRequest(
				version: version,
				networkID: networkID,
				manifest: manifest
			)

			return try engineToolkitClient.convertManifestInstructionsToJSONIfItWasString(conversionRequest)
		}

		return Self(
			convertManifestInstructionsToJSONIfItWasString: convertManifestInstructionsToJSONIfItWasString,
			addLockFeeInstructionToManifest: { maybeStringManifest in
				let manifestWithJSONInstructions: JSONInstructionsTransactionManifest
				do {
					manifestWithJSONInstructions = try await convertManifestInstructionsToJSONIfItWasString(maybeStringManifest)
				} catch {
					loggerGlobal.error("Failed to convert manifest: \(String(describing: error))")
					throw TransactionFailure.failedToPrepareForTXSigning(.failedToParseTXItIsProbablyInvalid)
				}

				var instructions = manifestWithJSONInstructions.instructions
				let networkID = await profileClient.getCurrentNetworkID()

				let version = engineToolkitClient.getTransactionVersion()

				let accountsSuitableToPayForTXFeeRequest = AccountAddressesInvolvedInTransactionRequest(
					version: version,
					manifest: manifestWithJSONInstructions.convertedManifestThatContainsThem,
					networkID: networkID
				)

				let lockFeeAmount: BigDecimal = 10

				let accountAddress: AccountAddress = try await { () async throws -> AccountAddress in
					let accountAddressesSuitableToPayTransactionFeeRef =
						try engineToolkitClient.accountAddressesSuitableToPayTransactionFee(accountsSuitableToPayForTXFeeRequest)

					let xrdContainersOptionals = await accountAddressesSuitableToPayTransactionFeeRef.concurrentMap { await accountPortfolioFetcher.fetchXRDBalance(of: $0, on: networkID) }
					let xrdContainers = xrdContainersOptionals.compactMap { $0 }
					let firstWithEnoughFunds = xrdContainers.first(where: { $0.amount >= lockFeeAmount })?.owner

					if let firstWithEnoughFunds = firstWithEnoughFunds {
						return firstWithEnoughFunds
					} else {
						throw TransactionFailure.failedToPrepareForTXSigning(.failedToFindAccountWithEnoughFundsToLockFee)
					}
				}()

				let lockFeeCallMethodInstruction = engineToolkitClient.lockFeeCallMethod(
					address: ComponentAddress(address: accountAddress.address),
					fee: lockFeeAmount.description
				).embed()

				instructions.insert(lockFeeCallMethodInstruction, at: 0)
				return TransactionManifest(instructions: instructions, blobs: maybeStringManifest.blobs)
			},
			signAndSubmitTransaction: signAndSubmitTransaction
		)
	}
}

// MARK: - NotaryAndSigners
struct NotaryAndSigners: Sendable, Hashable {
	/// Notary signer
	public let notarySigner: OnNetwork.Account
	/// Never empty, since this also contains the notary signer.
	public let accountsNeededToSign: NonEmpty<OrderedSet<OnNetwork.Account>>
}

// MARK: - CreateOnLedgerAccountFailedExpectedToFindAddressInNewGlobalEntities
struct CreateOnLedgerAccountFailedExpectedToFindAddressInNewGlobalEntities: Swift.Error {}

extension GatewayAPI.TransactionStatus {
	var isComplete: Bool {
		switch self {
		case .committedSuccess, .committedFailure, .rejected:
			return true
		case .pending, .unknown:
			return false
		}
	}
}

// MARK: - PollStrategy
public struct PollStrategy {
	public let maxPollTries: Int
	public let sleepDuration: TimeInterval
	public init(maxPollTries: Int, sleepDuration: TimeInterval) {
		self.maxPollTries = maxPollTries
		self.sleepDuration = sleepDuration
	}

	public static let `default` = Self(maxPollTries: 20, sleepDuration: 2)
}

// MARK: - GatewayAPI.TransactionCommittedDetailsResponse + Sendable
extension GatewayAPI.TransactionCommittedDetailsResponse: @unchecked Sendable {}

// MARK: - GatewayAPI.TransactionStatus + Sendable
extension GatewayAPI.TransactionStatus: @unchecked Sendable {}

// MARK: - FailedToGetDetailsOfSuccessfullySubmittedTX
struct FailedToGetDetailsOfSuccessfullySubmittedTX: LocalizedError, Equatable {
	public let txID: TXID
	var errorDescription: String? {
		"Successfully submitted TX with txID: \(txID) but failed to get transaction details for it."
	}
}

// MARK: - SubmitTXFailure
// FIXME: - mainnet: improve handling of polling failure
/// This failure might be a false positive, due to i.e. POLLING of tx failed, but TX might have
/// been submitted successfully. Or we might have successfully submitted the TX but failed to get details about it.
public enum SubmitTXFailure: Sendable, LocalizedError, Equatable {
	case failedToSubmitTX
	case invalidTXWasDuplicate(txID: TXID)

	/// Failed to poll, maybe TX was submitted successfully?
	case failedToPollTX(txID: TXID, error: FailedToPollError)

	case failedToGetTransactionStatus(txID: TXID, error: FailedToGetTransactionStatus)
	case invalidTXWasSubmittedButNotSuccessful(txID: TXID, status: TXFailureStatus)

	public var errorDescription: String? {
		switch self {
		case .failedToSubmitTX:
			return "Failed to submit transaction"
		case let .invalidTXWasDuplicate(txID):
			return "Duplicate TX id: \(txID)"
		case let .failedToPollTX(txID, error):
			return "\(error.localizedDescription) txID: \(txID)"
		case let .failedToGetTransactionStatus(txID, error):
			return "\(error.localizedDescription) txID: \(txID)"
		case let .invalidTXWasSubmittedButNotSuccessful(txID, status):
			return "Invalid TX submitted but not successful, status: \(status.localizedDescription) txID: \(txID)"
		}
	}
}

// MARK: - TXFailureStatus
public enum TXFailureStatus: String, LocalizedError, Sendable, Hashable {
	case rejected
	case failed
	public var errorDescription: String? {
		switch self {
		case .rejected: return "Rejected"
		case .failed: return "Failed"
		}
	}
}

// MARK: - FailedToPollError
public struct FailedToPollError: Sendable, LocalizedError, Equatable {
	public let error: Swift.Error
	public var errorDescription: String? {
		"Poll failed: \(String(describing: error))"
	}
}

// MARK: - FailedToGetTransactionStatus
public struct FailedToGetTransactionStatus: Sendable, LocalizedError, Equatable {
	public let pollAttempts: Int
	public var errorDescription: String? {
		"\(Self.self)(afterPollAttempts: \(String(describing: pollAttempts))"
	}
}

extension LocalizedError where Self: Equatable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.errorDescription == rhs.errorDescription
	}
}

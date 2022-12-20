import Collections
import Common
import Dependencies
import EngineToolkit
import EngineToolkitClient
import Foundation
import GatewayAPI
import NonEmpty
import Profile
import ProfileClient
import SLIP10

public extension TransactionClient {
	static var liveValue: Self {
		@Dependency(\.engineToolkitClient) var engineToolkitClient
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.profileClient) var profileClient

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

			let intentSignatures_: [SignatureWithPublicKey]
			do {
				intentSignatures_ = try await notaryAndSigners.signers.asyncMap { signer in
					// FIXME: mainnet: Sign with ALL provided signers of the account.
					try await signer.notarySigner(compiledTransactionIntent.compiledIntent)
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
				notarySignatureWithPublicKey = try await notaryAndSigners.notarySigner.notarySigner(
					compiledSignedIntent.compiledSignedIntent
				)
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
				notarizedTransactionHex: Data(compiledNotarizedTXIntent.compiledNotarizedIntent).hex
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
					atLedgerState: nil,
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
			getNotaryAndSigners: @Sendable (AccountAddressesNeedingToSignTransactionRequest) async throws -> NotaryAndSigners
		) async -> Result<(intent: TransactionIntent, notaryAndSigners: NotaryAndSigners), TransactionFailure.FailedToPrepareForTXSigning> {
			let nonce = engineToolkitClient.generateTXNonce()
			let epoch: Epoch
			do {
				epoch = try await gatewayAPIClient.getEpoch()
			} catch {
				return .failure(.failedToGetEpoch)
			}

			let version = engineToolkitClient.getTransactionVersion()

			let accountAddressesNeedingToSignTransactionRequest = AccountAddressesNeedingToSignTransactionRequest(
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
				notaryPublicKey = try notaryAndSigners.notarySigner.notaryPublicKey.intoEngine()
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
			getNotaryAndSigners: @escaping @Sendable (AccountAddressesNeedingToSignTransactionRequest) async throws -> NotaryAndSigners
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

				let signersForAccounts = try await profileClient.signersForAccountsGivenAddresses(
					.init(
						networkID: accountAddressesNeedingToSignTransactionRequest.networkID,
						addresses: addressesNeededToSign,
						keychainAccessFactorSourcesAuthPrompt: request.unlockKeychainPromptShowToUser
					)
				)

				let notary = await request.selectNotary(signersForAccounts)

				return .init(notarySigner: notary, signers: signersForAccounts)
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
				let manifestWithJSONInstructions = try await convertManifestInstructionsToJSONIfItWasString(maybeStringManifest)
				var instructions = manifestWithJSONInstructions.instructions
				let networkID = await profileClient.getCurrentNetworkID()

				let version = engineToolkitClient.getTransactionVersion()

				let accountAddressesNeedingToSignTransactionRequest = AccountAddressesNeedingToSignTransactionRequest(
					version: version,
					manifest: manifestWithJSONInstructions.convertedManifestThatContainsThem,
					networkID: networkID
				)

				let accountAddress: AccountAddress = try await { () async throws -> AccountAddress in
					// Might be empty
					let addressesManifestReferences =
						try engineToolkitClient.accountAddressesNeedingToSignTransaction(
							accountAddressesNeedingToSignTransactionRequest
						)
					if let address = addressesManifestReferences.first {
						return address
					} else {
						let accounts = try await profileClient.getAccounts()
						return accounts.first.address
					}
				}()

				let lockFeeCallMethodInstruction = engineToolkitClient.lockFeeCallMethod(
					address: ComponentAddress(address: accountAddress.address)
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
	public let notarySigner: SignersOfAccount
	/// Never empty, since this also contains the notary signer.
	public let signers: NonEmpty<OrderedSet<SignersOfAccount>>
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

public extension LocalizedError where Self: Equatable {
	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.errorDescription == rhs.errorDescription
	}
}

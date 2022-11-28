import Collections
import Common
import Dependencies
import EngineToolkit
import EngineToolkitClient
import Foundation
import struct GatewayAPI.GatewayAPIClient
import struct GatewayAPI.TransactionDetailsResponse
import struct GatewayAPI.TransactionLookupIdentifier
import struct GatewayAPI.TransactionStatus
import struct GatewayAPI.TransactionStatusRequest
import struct GatewayAPI.TransactionStatusResponse
import struct GatewayAPI.TransactionSubmitRequest
import struct GatewayAPI.TransactionSubmitResponse
import NonEmpty
import Profile
import ProfileClient
import SLIP10

// MARK: - TransactionClient
public struct TransactionClient: Sendable, DependencyKey {
	public var convertManifestInstructionsToJSONIfItWasString: ConvertManifestInstructionsToJSONIfItWasString
	public var addLockFeeInstructionToManifest: AddLockFeeInstructionToManifest
	public var signAndSubmitTransaction: SignAndSubmitTransaction
}

// MARK: TransactionClient.SignAndSubmitTransaction
public extension TransactionClient {
	typealias AddLockFeeInstructionToManifest = @Sendable (TransactionManifest) async throws -> TransactionManifest
	typealias ConvertManifestInstructionsToJSONIfItWasString = @Sendable (TransactionManifest) async throws -> JSONInstructionsTransactionManifest
	typealias SignAndSubmitTransaction = @Sendable (TransactionManifest) async -> TransactionResult
}

public typealias TransactionResult = Swift.Result<TXID, TransactionFailure>

// MARK: - TransactionFailure
public enum TransactionFailure: Sendable, LocalizedError, Equatable {
	case failedToPrepareForTXSigning(FailedToPrepareForTXSigning)
	case failedToCompileOrSign(CompileOrSignFailure)
	case failedToSubmit(SubmitTXFailure)
}

// MARK: TransactionFailure.FailedToPrepareForTXSigning
public extension TransactionFailure {
	enum FailedToPrepareForTXSigning: Sendable, Swift.Error, Equatable {
		case failedToGetEpoch
		case failedToLoadNotaryPrivateKey
		case failedToLoadNotaryPublicKey
	}
}

// MARK: TransactionFailure.CompileOrSignFailure
public extension TransactionFailure {
	enum CompileOrSignFailure: Sendable, Swift.Error, Equatable {
		case failedToCompileTXIntent
		case failedToGenerateTXId
		case failedToCompileSignedTXIntent
		case failedToSign
		case failedToConvertSignature
		case failedToCompileNotarizedTXIntent
	}
}

public extension DependencyValues {
	var transactionClient: TransactionClient {
		get { self[TransactionClient.self] }
		set { self[TransactionClient.self] = newValue }
	}
}

public extension TransactionClient {
	static var liveValue: Self {
		@Dependency(\.engineToolkitClient) var engineToolkitClient
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.profileClient) var profileClient

		let pollStrategy: PollStrategy = .default

		@Sendable
		func compileAndSign(
			transactionIntent: TransactionIntent,
			notary notaryPrivateKey: PrivateKey
		) async -> Result<(txID: TXID, compiledNotarizedTXIntent: CompileNotarizedTransactionIntentResponse), TransactionFailure.CompileOrSignFailure> {
			do {
				// Generate better error message than `failedToGenerateTXId` if failed to compileTXIntent
				_ = try engineToolkitClient.compileTransactionIntent(transactionIntent)
			} catch {
				return .failure(.failedToCompileTXIntent)
			}

			let txID: TXID
			do {
				txID = try engineToolkitClient.generateTXID(transactionIntent)
			} catch {
				return .failure(.failedToGenerateTXId)
			}

			let signedTransactionIntent = SignedTransactionIntent(
				intent: transactionIntent,
				intentSignatures: []
			)
			let compiledSignedIntent: CompileSignedTransactionIntentResponse
			do {
				compiledSignedIntent = try engineToolkitClient.compileSignedTransactionIntent(signedTransactionIntent)
			} catch {
				return .failure(.failedToCompileSignedTXIntent)
			}
			let notarySignatureWithPublicKey: SignatureWithPublicKey
			do {
				notarySignatureWithPublicKey = try notaryPrivateKey.signReturningHashOfMessage(
					data: compiledSignedIntent.compiledSignedIntent
				)
				.signatureWithPublicKey
			} catch {
				return .failure(.failedToSign)
			}

			let notarySignature: Engine.Signature
			do {
				notarySignature = try notarySignatureWithPublicKey.intoEngine().signature
			} catch {
				return .failure(.failedToConvertSignature)
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
				notarizedTransaction: Data(compiledNotarizedTXIntent.compiledNotarizedIntent).hex
			)

			let response: GatewayAPI.TransactionSubmitResponse

			do {
				response = try await gatewayAPIClient.submitTransaction(submitTransactionRequest)
			} catch {
				return .failure(.failedToSubmitTX)
			}

			guard !response.duplicate else {
				return .failure(.invalidTXWasDuplicate)
			}

			let transactionIdentifier = GatewayAPI.TransactionLookupIdentifier(
				origin: .intent,
				valueHex: txID.rawValue
			)

			// MARK: Poll Status
			var txStatus: GatewayAPI.TransactionStatus = .init(status: .pending)

			@Sendable func pollTransactionStatus() async throws -> GatewayAPI.TransactionStatus {
				let txStatusRequest = GatewayAPI.TransactionStatusRequest(
					transactionIdentifier: transactionIdentifier
				)
				let txStatusResponse = try await gatewayAPIClient.transactionStatus(txStatusRequest)
				return txStatusResponse.transaction.transactionStatus
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
			guard txStatus.status == .succeeded else {
				return .failure(.invalidTXWasSubmittedButNotSuccessful(txID: txID, status: txStatus.status))
			}

			return .success(txID)
		}

		@Sendable
		func signAndSubmit(
			transactionIntent: TransactionIntent,
			notary notaryPrivateKey: PrivateKey
		) async -> TransactionResult {
			await compileAndSign(transactionIntent: transactionIntent, notary: notaryPrivateKey)
				.mapError { TransactionFailure.failedToCompileOrSign($0) }
				.asyncFlatMap { (txID: TXID, compiledNotarizedTXIntent: CompileNotarizedTransactionIntentResponse) in
					await submitNotarizedTX(id: txID, compiledNotarizedTXIntent: compiledNotarizedTXIntent).mapError {
						TransactionFailure.failedToSubmit($0)
					}
				}
		}

		@Sendable
		func signAndSubmit(
			manifest: TransactionManifest,
			getNotary: @escaping (AccountAddressesNeedingToSignTransactionRequest) async throws -> PrivateKey
		) async -> TransactionResult {
			let networkID = await profileClient.getCurrentNetworkID()
			return await signAndSubmit(
				networkID: networkID,
				manifest: manifest,
				getNotary: getNotary
			)
		}

		@Sendable
		func signAndSubmit(
			networkID: NetworkID,
			manifest: TransactionManifest,
			getNotary: (AccountAddressesNeedingToSignTransactionRequest) async throws -> PrivateKey
		) async -> TransactionResult {
			func buildTransactionIntent() async -> Result<(intent: TransactionIntent, notaryPrivateKey: PrivateKey), TransactionFailure.FailedToPrepareForTXSigning> {
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

				let notaryPrivateKey: PrivateKey
				do {
					notaryPrivateKey = try await getNotary(accountAddressesNeedingToSignTransactionRequest)
				} catch {
					return .failure(.failedToLoadNotaryPrivateKey)
				}
				let notaryPublicKey: Engine.PublicKey
				do {
					notaryPublicKey = try notaryPrivateKey.publicKey().intoEngine()
				} catch {
					return .failure(.failedToLoadNotaryPublicKey)
				}

				let header = TransactionHeader(
					version: version,
					networkId: networkID,
					startEpochInclusive: epoch,
					endEpochExclusive: epoch + 5,
					nonce: nonce,
					publicKey: notaryPublicKey,
					notaryAsSignatory: true, // FIXME: - mainnet: pass as arg
					costUnitLimit: 10_000_000, // FIXME: - mainnet: pass as arg
					tipPercentage: 0 // FIXME: - mainnet: pass as arg
				)

				let intent = TransactionIntent(
					header: header,
					manifest: manifest
				)
				return .success((intent, notaryPrivateKey))
			}

			return await buildTransactionIntent().mapError {
				TransactionFailure.failedToPrepareForTXSigning($0)
			}.asyncFlatMap { intent, notaryPrivateKey in
				await signAndSubmit(transactionIntent: intent, notary: notaryPrivateKey)
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
				let lockFeeCallMethodInstruction = try engineToolkitClient.lockFeeCallMethod(faucetForNetwork: networkID).embed()
				instructions.insert(lockFeeCallMethodInstruction, at: 0)
				return TransactionManifest(instructions: instructions, blobs: maybeStringManifest.blobs)
			},
			signAndSubmitTransaction: { manifest in
				await signAndSubmit(manifest: manifest) { accountAddressesNeedingToSignTransactionRequest in

					// Might be empty
					let addressesNeededToSign = try engineToolkitClient
						.accountAddressesNeedingToSignTransaction(
							accountAddressesNeedingToSignTransactionRequest
						)

					// FIXME: - mainnet: pass as arg a fn: (NonEmpty<>)
					let selectNotary: @Sendable (NonEmpty<OrderedSet<PrivateKey>>) -> PrivateKey = {
						$0.first
					}

					let privateKeys = try await profileClient.privateKeysForAddresses(.init(addresses: .init(addressesNeededToSign), networkID: accountAddressesNeedingToSignTransactionRequest.networkID))

					let notaryPrivateKey = selectNotary(privateKeys)

					return notaryPrivateKey
				}
			}
		)
	}
}

#if DEBUG

import XCTestDynamicOverlay
extension TransactionClient: TestDependencyKey {
	public static let testValue: TransactionClient = .init(
		convertManifestInstructionsToJSONIfItWasString: unimplemented("\(Self.self).convertManifestInstructionsToJSONIfItWasString"),
		addLockFeeInstructionToManifest: unimplemented("\(Self.self).addLockFeeInstructionToManifest"),
		signAndSubmitTransaction: unimplemented("\(Self.self).signAndSubmitTransaction")
	)
}
#endif // DEBUG

// MARK: - CreateOnLedgerAccountFailedExpectedToFindAddressInNewGlobalEntities
struct CreateOnLedgerAccountFailedExpectedToFindAddressInNewGlobalEntities: Swift.Error {}

extension GatewayAPI.TransactionStatus {
	var isComplete: Bool {
		switch status {
		case .succeeded, .failed, .rejected:
			return true
		case .pending:
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

// MARK: - GatewayAPI.TransactionDetailsResponse + Sendable
extension GatewayAPI.TransactionDetailsResponse: @unchecked Sendable {}

// MARK: - GatewayAPI.TransactionStatus.Status + Sendable
extension GatewayAPI.TransactionStatus.Status: @unchecked Sendable {}

// MARK: - FailedToGetDetailsOfSuccessfullySubmittedTX
struct FailedToGetDetailsOfSuccessfullySubmittedTX: LocalizedError, Equatable {
	public let txID: TXID
	var errorDescription: String? {
		"Successfully submitted TX with txID: \(txID) but failed to get transaction details for it."
	}
}

// MARK: - SubmitTXFailure
// FIXME: - mainnet: improve hanlding of polling failure
/// This failure might be a false positive, due to i.e. POLLING of tx failed, but TX might have
/// been submitted successfully. Or we might have successfully submitted the TX but failed to get details about it.
public enum SubmitTXFailure: Sendable, LocalizedError, Equatable {
	case failedToSubmitTX
	case invalidTXWasDuplicate

	/// Failed to poll, maybe TX was submitted successfuly?
	case failedToPollTX(txID: TXID, error: FailedToPollError)

	case failedToGetTransactionStatus(txID: TXID, error: FailedToGetTransactionStatus)
	case invalidTXWasSubmittedButNotSuccessful(txID: TXID, status: GatewayAPI.TransactionStatus.Status)
}

// MARK: - FailedToPollError
public struct FailedToPollError: Sendable, LocalizedError, Equatable {
	public let error: Swift.Error
	public var errorDescription: String? {
		"\(Self.self)(error: \(String(describing: error))"
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

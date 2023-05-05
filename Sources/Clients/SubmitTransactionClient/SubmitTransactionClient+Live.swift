import ClientPrelude
import EngineToolkitClient
import EngineToolkitModels
import GatewayAPI

// MARK: - SubmitTransactionClient + DependencyKey
extension SubmitTransactionClient: DependencyKey {
	public typealias Value = SubmitTransactionClient

	public static let liveValue: Self = {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		let transactionStatusUpdates: TransactionStatusUpdates = { txID, pollStrategy in
			@Dependency(\.continuousClock) var clock

			let statusSubject = AsyncCurrentValueSubject<TransactionStatusUpdate>.init(.init(txID: txID, result: .success(.pending)))

			@Sendable func pollTransactionStatus() async throws -> GatewayAPI.TransactionStatus {
				let txStatusRequest = GatewayAPI.TransactionStatusRequest(
					intentHashHex: txID.rawValue
				)
				let txStatusResponse = try await gatewayAPIClient.transactionStatus(txStatusRequest)
				return txStatusResponse.status
			}

			let pollCountHolder = ActorIsolated<Int>(0)

			Task {
				while !statusSubject.value.result.isComplete {
					await pollCountHolder.withValue { pollCount in
						if pollCount >= pollStrategy.maxPollTries {
							statusSubject.send(.init(
								txID: txID,
								result: .failure(.failedToGetTransactionStatus(
									txID: txID,
									error: .init(pollAttempts: pollCount)
								))
							))

						} else {
							pollCount += 1
						}
					}
					try? await clock.sleep(for: .seconds(pollStrategy.sleepDuration))
					let status = try await pollTransactionStatus()
					statusSubject.send(.init(txID: txID, result: .success(status)))
				}
			}

			return statusSubject.eraseToAnyAsyncSequence()
		}

		let hasTXBeenCommittedSuccessfully: HasTXBeenCommittedSuccessfully = { txID in
			for try await update in try await transactionStatusUpdates(txID, .default) {
				guard update.txID == txID else { continue }
				switch update.result {
				case .success(.committedFailure):
					throw TXFailureStatus.failed
				case .success(.rejected):
					throw TXFailureStatus.rejected
				case .success(.committedSuccess):
					return
				case let .failure(error):
					throw error
				case .success(.unknown):
					continue
				case .success(.pending):
					continue
				}
			}
			throw CancellationError()
		}

		return Self(
			submitTransaction: { request in
				let txID = request.txID

				func debugPrintTX() {
					@Dependency(\.engineToolkitClient) var engineToolkitClient

					do {
						let decompiledNotarized = try engineToolkitClient.decompileNotarizedTransactionIntent(.init(
							compiledNotarizedIntent: Array(request.compiledNotarizedTXIntent.compiledIntent),
							instructionsOutputKind: .parsed
						))
						let signedIntent = decompiledNotarized.signedIntent
						let notarySignature = decompiledNotarized.notarySignature
						let intent = signedIntent.intent
						let intentSignatures = signedIntent.intentSignatures
						// RET prints when convertManifest is called, when it is removed, this can be moved down
						// inline inside `print`.
						let txIntentString = intent.description(lookupNetworkName: { try? Radix.Network.lookupBy(id: $0).name.rawValue })
						print("\n\n🔮 DEBUG TRANSACTION START 🔮a")
						print("TXID: \(txID.rawValue)")
						print("TransactionIntent: \(txIntentString)")
						print("\n\nINTENT SIGNATURES: \(intentSignatures.map { "\npublicKey: \($0.publicKey?.compressedRepresentation.hex ?? "")\nsig: \($0.signature.bytes.hex)" }.joined(separator: "\n"))")
						print("\nNOTARY SIGNATURE: \(notarySignature)")
						print("\n\nCOMPILED TX INTENT:\n\(request.compiledNotarizedTXIntent.compiledIntent.hex)")
						print("\n\nCOMPILED NOTARIZED INTENT:\n\(request.compiledNotarizedTXIntent.compiledIntent.hex)")
						print("\n\n\n🔮 DEBUG TRANSACTION END 🔮\n\n")
					} catch {}
				}
				debugPrintTX()

				let submitTransactionRequest = GatewayAPI.TransactionSubmitRequest(
					notarizedTransactionHex: Data(request.compiledNotarizedTXIntent.compiledIntent).hex
				)

				let response = try await gatewayAPIClient.submitTransaction(submitTransactionRequest)

				guard !response.duplicate else {
					throw SubmitTXFailure.invalidTXWasDuplicate(txID: txID)
				}
				return txID
			},
			transactionStatusUpdates: transactionStatusUpdates,
			hasTXBeenCommittedSuccessfully: hasTXBeenCommittedSuccessfully
		)
	}()
}

extension Result where Success == GatewayAPI.TransactionStatus {
	var isComplete: Bool {
		switch self {
		case .failure: return true
		case let .success(status): return status.isComplete
		}
	}
}

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
public enum SubmitTXFailure: Sendable, LocalizedError, Equatable {
	case failedToSubmitTX
	case invalidTXWasDuplicate(txID: TXID)

	public var errorDescription: String? {
		switch self {
		case .failedToSubmitTX:
			return "Failed to submit transaction"
		case let .invalidTXWasDuplicate(txID):
			return "Duplicate TX id: \(txID)"
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

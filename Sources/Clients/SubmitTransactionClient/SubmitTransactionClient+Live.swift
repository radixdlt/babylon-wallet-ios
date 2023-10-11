import AccountPortfoliosClient
import ClientPrelude
import EngineKit
import GatewayAPI
import OnLedgerEntitiesClient
import TransactionClient

// MARK: - SubmitTransactionClient + DependencyKey
extension SubmitTransactionClient: DependencyKey {
	public typealias Value = SubmitTransactionClient

	public static let liveValue: Self = {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		let transactionStatusUpdates: TransactionStatusUpdates = { txID, pollStrategy in
			@Dependency(\.continuousClock) var clock

			let statusSubject = AsyncCurrentValueSubject<TransactionStatusUpdate>(.init(txID: txID, result: .success(.pending)))

			@Sendable func pollTransactionStatus() async throws -> GatewayAPI.TransactionStatus {
				let txStatusRequest = GatewayAPI.TransactionStatusRequest(
					intentHash: txID.asStr()
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
					do {
						let status = try await pollTransactionStatus()
						statusSubject.send(.init(txID: txID, result: .success(status)))
					} catch {
						loggerGlobal.error("Failed to poll transaction status: \(error.localizedDescription)")
						switch error {
						case is BadHTTPResponseCode, is BadHTTPResponseCode, is ResponseDecodingError:
							/// Terminate polling, GW returned wrong response
							await statusSubject.send(.init(
								txID: txID,
								result: .failure(.failedToGetTransactionStatus(txID: txID, error: .init(pollAttempts: pollCountHolder.value)))
							))
						default:
							/// Continue polling, the poll failed due to internal URLSession error.
							break
						}
					}
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

		let submitTransaction: SubmitTransaction = { request in
			let txID = request.txID

			func debugPrintTX(_ decompiledNotarized: NotarizedTransaction) {
				let signedIntent = decompiledNotarized.signedIntent()
				let notarySignature = decompiledNotarized.notarySignature()
				let intent = signedIntent.intent()
				let intentSignatures = signedIntent.intentSignatures()
				// RET prints when convertManifest is called, when it is removed, this can be moved down
				// inline inside `print`.
				let txIntentString = intent.description(lookupNetworkName: { try? Radix.Network.lookupBy(id: $0).name.rawValue })
				loggerGlobal.debug("\n\n🔮 DEBUG TRANSACTION START 🔮")
				loggerGlobal.debug("TXID: \(txID.asStr())")
				let tooManyBytesToPrint = 6000 // competely arbitrarily chosen should not take long time to print is the point...
				if txIntentString.count < tooManyBytesToPrint {
					loggerGlobal.debug("TransactionIntent: \(txIntentString)")
				} else {
					loggerGlobal.debug("TransactionIntent <Manifest too big, header only> \(intent.header().description(lookupNetworkName: { try? Radix.Network.lookupBy(id: $0).name.rawValue }))")
				}
				loggerGlobal.debug("\n\nINTENT SIGNATURES: \(intentSignatures.map { "\npublicKey: \($0.publicKey?.bytes.hex ?? "")\nsig: \($0.signature.bytes.hex)" }.joined(separator: "\n"))")
				loggerGlobal.debug("\nNOTARY SIGNATURE: \(notarySignature.bytes.hex)")
				if request.compiledNotarizedTXIntent.count < tooManyBytesToPrint {
					loggerGlobal.debug("\n\nCOMPILED NOTARIZED INTENT:\n\(request.compiledNotarizedTXIntent.hex)")
				} else {
					loggerGlobal.debug("\n\nCOMPILED NOTARIZED INTENT: <TOO BIG TO PRINT>")
				}
				loggerGlobal.debug("\n\n\n🔮 DEBUG TRANSACTION END 🔮\n\n")
			}

			@Dependency(\.transactionClient) var transactionClient
			@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
			@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
			@Dependency(\.cacheClient) var cacheClient

			let changedAccounts: [Profile.Network.Account.EntityAddress]?
			let resourceAddressesToRefresh: [Address]?
			do {
				let decompiledNotarized = try NotarizedTransaction.decompile(compiledNotarizedTransaction: request.compiledNotarizedTXIntent)

				#if DEBUG
				debugPrintTX(decompiledNotarized)
				#endif

				let manifest = decompiledNotarized.signedIntent().intent().manifest()

				let involvedAccounts = try await transactionClient.myInvolvedEntities(manifest)
				changedAccounts = involvedAccounts.accountsDepositedInto
					.union(involvedAccounts.accountsWithdrawnFrom)
					.map(\.address)

				let involvedAddresses = manifest.extractAddresses()
				/// Refresh the resources if an operation on resource pool is involved,
				/// reason being that contributing or withdrawing from a resource pool modifies the totalSupply
				if involvedAddresses.contains(where: \.key.isResourcePool) {
					/// A little bit to aggresive, as any other resource will also be refreshed.
					/// But at this stage we cannot determine(without making additional calls) the pool unit related fungible resource
					resourceAddressesToRefresh = involvedAddresses
						.filter { $0.key == .globalFungibleResourceManager || $0.key.isResourcePool }
						.values
						.flatMap(identity)
						.compactMap { try? $0.asSpecific() }
				} else {
					resourceAddressesToRefresh = nil
				}
			} catch {
				loggerGlobal.warning("Could get transactionClient.myInvolvedEntities: \(error.localizedDescription)")
				changedAccounts = nil
				resourceAddressesToRefresh = nil
			}

			let submitTransactionRequest = GatewayAPI.TransactionSubmitRequest(
				notarizedTransactionHex: request.compiledNotarizedTXIntent.hex()
			)

			let response = try await gatewayAPIClient.submitTransaction(submitTransactionRequest)

			guard !response.duplicate else {
				throw SubmitTXFailure.invalidTXWasDuplicate(txID: txID)
			}

			Task.detached {
				try await hasTXBeenCommittedSuccessfully(txID)

				if let resourceAddressesToRefresh {
					resourceAddressesToRefresh.forEach {
						cacheClient.removeFile(.onLedgerEntity(.resource($0.asGeneral)))
					}
				}

				if let changedAccounts {
					// FIXME: Ideally we should only have to call the cacheClient here
					// cacheClient.clearCacheForAccounts(Set(changedAccounts))
					_ = try await accountPortfoliosClient.fetchAccountPortfolios(changedAccounts, true)
				}
			}

			return txID
		}

		return Self(
			submitTransaction: submitTransaction,
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

	public init(pollAttempts: Int) {
		self.pollAttempts = pollAttempts
	}
}

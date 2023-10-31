// MARK: - SubmitTransactionClient + DependencyKey
extension SubmitTransactionClient: DependencyKey {
	public typealias Value = SubmitTransactionClient

	public static let liveValue: Self = {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		let transactionStatusUpdates: TransactionStatusUpdates = { txID, pollStrategy in
			@Dependency(\.continuousClock) var clock

			let statusSubject = AsyncCurrentValueSubject<TransactionStatusUpdate>(.init(txID: txID, result: .idle))

			@Sendable func pollTransactionStatus() async throws -> GatewayAPI.TransactionStatusResponse {
				let txStatusRequest = GatewayAPI.TransactionStatusRequest(
					intentHash: txID.asStr()
				)
				let txStatusResponse = try await gatewayAPIClient.transactionStatus(txStatusRequest)
				return txStatusResponse
			}

			Task {
				statusSubject.send(.init(txID: txID, result: .loading))
				while true {
					guard let transactionStatus = try? await pollTransactionStatus().knownPayloads.first?.payloadStatus else {
						loggerGlobal.error("No payload status?")
						continue
					}

					loggerGlobal.info("Payload status is \(transactionStatus)")

					switch transactionStatus {
					case .unknown, .commitPendingOutcomeUnknown, .pending:
						try? await clock.sleep(for: .seconds(pollStrategy.sleepDuration))
						continue
					case .committedSuccess:
						statusSubject.send(.init(txID: txID, result: .success(.instance)))
						return
					case .committedFailure:
						statusSubject.send(.init(txID: txID, result: .failure(TXFailureStatus.failed)))
						return
					case .permanentlyRejected:
						statusSubject.send(.init(txID: txID, result: .failure(TXFailureStatus.permanentlyRejected)))
						return
					case .temporarilyRejected:
						statusSubject.send(.init(txID: txID, result: .failure(TXFailureStatus.temporarilyRejected)))
						return
					}
				}
			}

			return statusSubject.eraseToAnyAsyncSequence()
		}

		let hasTXBeenCommittedSuccessfully: HasTXBeenCommittedSuccessfully = { txID in
			for try await update in try await transactionStatusUpdates(txID, .default) {
				guard update.txID == txID else { continue }
				switch update.result {
				case .idle, .loading:
					continue
				case .success:
					return
				case let .failure(error):
					throw error
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
					/// A little bit too aggressive, as any other resource will also be refreshed.
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
		case .failure: true
		case let .success(status): status.isComplete
		}
	}
}

extension GatewayAPI.TransactionStatus {
	var isComplete: Bool {
		switch self {
		case .committedSuccess, .committedFailure, .rejected:
			true
		case .pending, .unknown:
			false
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
			"Failed to submit transaction"
		case let .invalidTXWasDuplicate(txID):
			"Duplicate TX id: \(txID)"
		}
	}
}

// MARK: - TXFailureStatus
public enum TXFailureStatus: String, LocalizedError, Sendable, Hashable {
	case permanentlyRejected
	case temporarilyRejected
	case failed
	public var errorDescription: String? {
		switch self {
		case .permanentlyRejected: "Permanently Rejected"
		case .temporarilyRejected: "Temporarily Rejected"
		case .failed: "Failed"
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

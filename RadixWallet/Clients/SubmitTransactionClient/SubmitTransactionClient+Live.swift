// MARK: - SubmitTransactionClient + DependencyKey
extension SubmitTransactionClient: DependencyKey {
	public typealias Value = SubmitTransactionClient

	public static let liveValue: Self = {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		let hasTXBeenCommittedSuccessfully: HasTXBeenCommittedSuccessfully = { txID in
			@Dependency(\.continuousClock) var clock

			@Sendable func pollTransactionStatus() async throws -> GatewayAPI.TransactionStatusResponse {
				let txStatusRequest = GatewayAPI.TransactionStatusRequest(
					intentHash: txID.description
				)
				let txStatusResponse = try await gatewayAPIClient.transactionStatus(txStatusRequest)
				return txStatusResponse
			}

			var delayDuration = PollStrategy.default.sleepDuration

			while true {
				guard !Task.isCancelled else {
					throw CancellationError()
				}

				// Increase delay by 1 second on subsequent calls
				delayDuration += 1

				guard let transactionStatusResponse = try? await pollTransactionStatus(),
				      let transactionStatus = transactionStatusResponse.knownPayloads.first?.payloadStatus
				else {
					try? await clock.sleep(for: .seconds(delayDuration))
					continue
				}

				switch transactionStatus {
				case .unknown, .commitPendingOutcomeUnknown, .pending:
					try? await clock.sleep(for: .seconds(delayDuration))
					continue
				case .committedSuccess:
					return
				case .committedFailure:
					throw TXFailureStatus.failed(reason: .init(transactionStatusResponse.errorMessage))
				case .permanentlyRejected:
					throw TXFailureStatus.permanentlyRejected(reason: .init(transactionStatusResponse.errorMessage))
				case .temporarilyRejected:
					throw TXFailureStatus.temporarilyRejected(currentEpoch: .init(UInt64(transactionStatusResponse.ledgerState.epoch)))
				}
			}
		}

		let submitTransaction: SubmitTransaction = { request in
			let txID = request.txID

			#if DEBUG
			debugPrintCompiledNotarizedIntent(
				compiled: request.compiledNotarizedTXIntent
			)
			#endif

			let submitTransactionRequest = GatewayAPI.TransactionSubmitRequest(
				notarizedTransactionHex: request.compiledNotarizedTXIntent.data.hex
			)

			let response = try await gatewayAPIClient.submitTransaction(submitTransactionRequest)

			guard !response.duplicate else {
				throw SubmitTXFailure.invalidTXWasDuplicate(txID: txID)
			}

			return txID
		}

		return Self(
			submitTransaction: submitTransaction,
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
public enum TXFailureStatus: LocalizedError, Sendable, Hashable {
	case permanentlyRejected(reason: Reason)
	case temporarilyRejected(currentEpoch: Epoch)
	case failed(reason: Reason)

	public var errorDescription: String? {
		switch self {
		case .permanentlyRejected: "Permanently Rejected"
		case .temporarilyRejected: "Temporarily Rejected"
		case .failed: "Failed"
		}
	}
}

// MARK: TXFailureStatus.Reason
extension TXFailureStatus {
	public enum Reason: Sendable, Hashable, Equatable {
		public enum ApplicationError: Equatable, Sendable, Hashable {
			public enum WorktopError: Sendable, Hashable, Equatable {
				case assertionFailed
			}

			case worktopError(WorktopError)
		}

		case applicationError(ApplicationError)
		case unknown
	}
}

extension TXFailureStatus.Reason {
	public init(_ rawError: String?) {
		guard let rawError else {
			self = .unknown
			return
		}

		if rawError.contains("AssertionFailed") {
			self = .applicationError(.worktopError(.assertionFailed))
		} else {
			self = .unknown
		}
	}
}

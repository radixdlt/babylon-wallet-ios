// MARK: - SubmitTransactionClient + DependencyKey
extension SubmitTransactionClient: DependencyKey {
	public typealias Value = SubmitTransactionClient

	public static let liveValue: Self = {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		let hasTXBeenCommittedSuccessfully: HasTXBeenCommittedSuccessfully = { txID in
			@Dependency(\.continuousClock) var clock

			@Sendable func pollTransactionStatus() async throws -> GatewayAPI.TransactionStatusResponse {
				let txStatusRequest = GatewayAPI.TransactionStatusRequest(
					intentHash: txID.asStr()
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

			do {
				#if DEBUG
				let decompiledNotarized = try NotarizedTransaction.decompile(compiledNotarizedTransaction: Data(request.compiledNotarizedTXIntent))
				debugPrintTX(decompiledNotarized)
				#endif
			} catch {}

			let submitTransactionRequest = GatewayAPI.TransactionSubmitRequest(
				notarizedTransactionHex: request.compiledNotarizedTXIntent.hex()
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
			public enum WorktopError: String, Sendable, Hashable, Equatable {
				case assertionFailed = "AssertionFailed"
			}

			case worktopError(WorktopError)
		}

		case applicationError(ApplicationError)
		case unknown
	}
}

/// Rudimentary parser combinator algo
extension TXFailureStatus.Reason {
	public init(_ rawError: String?) {
		guard let rawError else {
			self = .unknown
			return
		}

		let components = rawError.components(separatedBy: CharacterSet(charactersIn: "()"))
			.flatMap { $0.split(separator: " ") }
			.map(String.init)

		switch components.first {
		case "ApplicationError":
			guard let wrappedCase = ApplicationError(components.dropFirst()) else {
				self = .unknown
				return
			}
			self = .applicationError(wrappedCase)
		default:
			self = .unknown
		}
	}
}

extension TXFailureStatus.Reason.ApplicationError {
	init?(_ rawErrorComponents: ArraySlice<String>) {
		guard let firstComponent = rawErrorComponents.first else {
			return nil
		}

		switch firstComponent {
		case "WorktopError":
			guard let wrappedCase = WorktopError(rawErrorComponents.dropFirst()) else {
				return nil
			}
			self = .worktopError(wrappedCase)
		default:
			return nil
		}
	}
}

extension TXFailureStatus.Reason.ApplicationError.WorktopError {
	init?(_ rawErrorComponents: ArraySlice<String>) {
		guard let firstComponent = rawErrorComponents.first else {
			return nil
		}

		switch firstComponent {
		case "AssertionFailed":
			self = .assertionFailed
		default:
			return nil
		}
	}
}

import EngineToolkitClient
import FeaturePrelude
import TransactionClient

// MARK: - TransactionSigning
public struct TransactionSigning: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let transactionManifestWithoutLockFee: TransactionManifest
		var transactionWithLockFee: TransactionManifest?
		var transactionWithLockFeeString: String?
		var makeTransactionHeaderInput: MakeTransactionHeaderInput
		var isSigningTX: Bool = false

		public init(
			transactionManifestWithoutLockFee: TransactionManifest,
			transactionWithLockFee: TransactionManifest? = nil, // TODO: remove?
			makeTransactionHeaderInput: MakeTransactionHeaderInput = .default
		) {
			self.transactionManifestWithoutLockFee = transactionManifestWithoutLockFee
			self.transactionWithLockFee = transactionWithLockFee
			self.makeTransactionHeaderInput = makeTransactionHeaderInput
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case didAppear
		case signTransactionButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadNetworkIDResult(TaskResult<NetworkID>, manifestWithFeeLock: TransactionManifest)
		case addLockFeeInstructionToManifestResult(TaskResult<TransactionManifest>)
		case signTransactionResult(TransactionResult)
	}

	public enum DelegateAction: Sendable, Equatable {
		case failed(ApproveTransactionFailure)
		case signedTXAndSubmittedToGateway(TransactionIntent.TXID)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.transactionClient) var transactionClient
	@Dependency(\.profileClient) var profileClient

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .didAppear:
			return .run { [manifest = state.transactionManifestWithoutLockFee] send in
				await send(.internal(.addLockFeeInstructionToManifestResult(
					TaskResult {
						try await transactionClient.addLockFeeInstructionToManifest(manifest)
					}
				)))
			}

		case .signTransactionButtonTapped:
			guard
				let transactionWithLockFee = state.transactionWithLockFee
			else {
				return .none
			}

			state.isSigningTX = true

			let signRequest = SignManifestRequest(
				manifestToSign: transactionWithLockFee,
				makeTransactionHeaderInput: state.makeTransactionHeaderInput,
				unlockKeychainPromptShowToUser: L10n.TransactionSigning.biometricsPrompt
			)

			return .run { send in
				await send(.internal(.signTransactionResult(
					await transactionClient.signAndSubmitTransaction(signRequest)
				)))
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .addLockFeeInstructionToManifestResult(.success(transactionWithLockFee)):
			state.transactionWithLockFee = transactionWithLockFee
			return .run { send in
				await send(.internal(.loadNetworkIDResult(
					TaskResult { await profileClient.getCurrentNetworkID() },
					manifestWithFeeLock: transactionWithLockFee
				)))
			}

		case let .loadNetworkIDResult(.success(networkID), manifestWithFeeLock):
			state.transactionWithLockFeeString = manifestWithFeeLock.toString(
				preamble: "",
				blobOutputFormat: .includeBlobsByByteCountOnly,
				blobPreamble: "\n\nBLOBS:\n",
				networkID: networkID
			)
			return .none

		case let .loadNetworkIDResult(.failure(error), _):
			errorQueue.schedule(error)
			return .send(.delegate(.failed(ApproveTransactionFailure.prepareTransactionFailure(.loadNetworkID(error)))))

		case let .addLockFeeInstructionToManifestResult(.failure(error)):
			errorQueue.schedule(error)
			return .send(.delegate(.failed(ApproveTransactionFailure.prepareTransactionFailure(.addTransactionFee(error)))))

		case let .signTransactionResult(.success(txID)):
			state.isSigningTX = false
			return .send(.delegate(.signedTXAndSubmittedToGateway(txID)))

		case let .signTransactionResult(.failure(transactionFailure)):
			state.isSigningTX = false
			return .send(.delegate(.failed(.transactionFailure(transactionFailure))))
		}
	}
}

// MARK: - ApproveTransactionFailure
public enum ApproveTransactionFailure: Sendable, LocalizedError, Equatable {
	public enum PrepareTransactionFailure: Sendable, LocalizedError, Equatable {
		public static func == (lhs: Self, rhs: Self) -> Bool {
			lhs.errorDescription == rhs.errorDescription
		}

		case addTransactionFee(Swift.Error)
		case loadNetworkID(Swift.Error)
		public var errorDescription: String? {
			switch self {
			case let .addTransactionFee(error):
				let message = "Failed to add fee to transaction manifest"
				guard let engineToolkitError = error as? EngineToolkit.Error else {
					return message
				}
				return "\(message), engine toolkit: \(String(describing: engineToolkitError.errorDescription))"
			case let .loadNetworkID(error):
				return "Failed to load network ID, reason: \(String(describing: error))"
			}
		}
	}

	case prepareTransactionFailure(PrepareTransactionFailure)
	case transactionFailure(TransactionFailure)

	public var errorDescription: String? {
		switch self {
		case let .prepareTransactionFailure(error):
			return error.localizedDescription
		case let .transactionFailure(error):
			return error.localizedDescription
		}
	}
}

public extension EngineToolkit.Error {
	var errorDescription: String? {
		switch self {
		case let .callLibraryFunctionFailure(callLibraryFunctionFailure):
			switch callLibraryFunctionFailure {
			case .allocatedMemoryForResponseFailedCouldNotUTF8EncodeCString:
				return "Failed to allocate memory for response, could not utf8 encode string."
			case .noReturnedOutputFromLibraryFunction:
				return "No returned output from library function."
			}
		case let .deserializeResponseFailure(deserializeResponseFailure):
			switch deserializeResponseFailure {
			case let .beforeDecodingError(beforeDecodingError):
				switch beforeDecodingError {
				case .failedToUTF8EncodeResponseJSONString:
					return "Failed to utf8 encode response JSON string."
				}
			case let .decodeResponseFailedAndCouldNotDecodeAsErrorResponseEither(responseType, decodingError):
				return "Failed to decode response as \(responseType), underlying decoding error: \(decodingError)."
			case let .decodeResponseFailedAndCouldNotDecodeAsErrorResponseEitherNorAsSwiftDecodingError(responseType, nonSwiftDecodingError):
				return "Failed to decode response as \(responseType), underlying error: \(nonSwiftDecodingError)."
			case let .errorResponse(errorResponse):
				return "Internal toolkit error: \(String(describing: errorResponse))"
			}
		case let .serializeRequestFailure(serializeRequestFailure):
			switch serializeRequestFailure {
			case .jsonEncodeRequestFailed:
				return "JSON encode request failed."
			case .utf8DecodingFailed:
				return "UTF8 decoding failed"
			}
		}
	}
}

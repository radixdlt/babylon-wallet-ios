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

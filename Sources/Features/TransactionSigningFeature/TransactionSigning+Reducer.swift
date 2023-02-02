import EngineToolkitClient
import FeaturePrelude
import TransactionClient

// MARK: - TransactionSigning
public struct TransactionSigning: Sendable, ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.transactionClient) var transactionClient
	@Dependency(\.profileClient) var profileClient
	public init() {}
}

public extension TransactionSigning {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.didAppear)):
			return .run { [manifest = state.transactionManifestWithoutLockFee] send in
				await send(.internal(.addLockFeeInstructionToManifestResult(
					TaskResult {
						try await transactionClient.addLockFeeInstructionToManifest(manifest)
					}
				)))
			}

		case let .internal(.addLockFeeInstructionToManifestResult(.success(transactionWithLockFee))):
			state.transactionWithLockFee = transactionWithLockFee
			return .run { send in
				await send(.internal(.loadNetworkIDResult(
					TaskResult { await profileClient.getCurrentNetworkID() },
					manifestWithFeeLock: transactionWithLockFee
				)))
			}

		case let .internal(.loadNetworkIDResult(.success(networkID), manifestWithFeeLock)):
			state.transactionWithLockFeeString = manifestWithFeeLock.toString(
				preamble: "",
				blobOutputFormat: .includeBlobsByByteCountOnly,
				blobPreamble: "\n\nBLOBS:\n",
				networkID: networkID
			)
			return .none

		case let .internal(.loadNetworkIDResult(.failure(error), _)):
			errorQueue.schedule(error)
			return .run { send in
				await send(.delegate(.failed(ApproveTransactionFailure.prepareTransactionFailure(.loadNetworkID(error)))))
			}

		case let .internal(.addLockFeeInstructionToManifestResult(.failure(error))):
			errorQueue.schedule(error)
			return .run { send in
				await send(.delegate(.failed(ApproveTransactionFailure.prepareTransactionFailure(.addTransactionFee(error)))))
			}

		case .internal(.view(.signTransactionButtonTapped)):
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

		case let .internal(.signTransactionResult(.success(txID))):
			state.isSigningTX = false

			return .run { send in
				await send(.delegate(
					.signedTXAndSubmittedToGateway(txID)
				))
			}

		case let .internal(.signTransactionResult(.failure(transactionFailure))):
			state.isSigningTX = false
			return .run { send in
				await send(.delegate(.failed(.transactionFailure(transactionFailure))))
			}

		case .internal(.view(.dismissButtonTapped)):
			return .run { send in
				await send(.delegate(.rejected))
			}

		case .delegate:
			return .none
		}
	}
}

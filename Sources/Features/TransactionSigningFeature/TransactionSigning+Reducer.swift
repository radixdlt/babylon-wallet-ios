import ComposableArchitecture
import EngineToolkitClient
import ErrorQueue
import Foundation
import TransactionClient

// MARK: - TransactionSigning
public struct TransactionSigning: ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.transactionClient) var transactionClient
	@Dependency(\.profileClient) var profileClient
	public init() {}
}

public extension TransactionSigning {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.didAppear)):
			return .run { [transactionClient, manifest = state.transactionManifestWithoutLockFee] send in
				await send(.internal(.addLockFeeInstructionToManifestResult(
					TaskResult {
						try await transactionClient.addLockFeeInstructionToManifest(manifest)
					}
				)))
			}

		case let .internal(.addLockFeeInstructionToManifestResult(.success(transactionWithLockFee))):
			state.transactionWithLockFee = transactionWithLockFee
			return .run { [profileClient] send in
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
			return .none

		case let .internal(.addLockFeeInstructionToManifestResult(.failure(error))):
			errorQueue.schedule(error)
			return .none

		case .internal(.view(.signTransactionButtonTapped)):
			guard
				let transactionWithLockFee = state.transactionWithLockFee
			else {
				return .none
			}

			state.isSigningTX = true

			return .run { [transactionClient] send in
				await send(.internal(.signTransactionResult(TaskResult {
					try await transactionClient.signAndSubmitTransaction(transactionWithLockFee).txID
				})))
			}

		case let .internal(.signTransactionResult(.success(txid))):
			state.isSigningTX = false

			return .run { [request = state.request] send in
				await send(.delegate(
					.signedTXAndSubmittedToGateway(
						txid,
						request: request
					)
				))
			}

		case let .internal(.signTransactionResult(.failure(error))):
			state.isSigningTX = false
			errorQueue.schedule(error)
			return .none

		case .internal(.view(.closeButtonTapped)):
			return .run { [dismissedRequest = state.request] send in
				await send(.delegate(.dismissed(dismissedRequest)))
			}

		case .delegate:
			return .none
		}
	}
}

import ComposableArchitecture
import EngineToolkitClient
import ErrorQueue
import Foundation
import TransactionClient

// MARK: - TransactionSigning
public struct TransactionSigning: ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.transactionClient) var transactionClient
	public init() {}
}

public extension TransactionSigning {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.signTransactionButtonTapped)):
			state.isSigningTX = true
			return .run { [transactionManifest = state.transactionManifest] send in
				await send(.internal(.signTransactionResult(TaskResult {
					try await transactionClient.signAndSubmitTransaction(transactionManifest).txID
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

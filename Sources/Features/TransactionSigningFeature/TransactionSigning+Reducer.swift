import ComposableArchitecture
import EngineToolkitClient
import ErrorQueue
import Foundation
import ProfileClient

// MARK: - TransactionSigning
public struct TransactionSigning: ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.profileClient) var profileClient

	public init() {}
}

public extension TransactionSigning {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.signTransactionButtonTapped)):
			state.isSigningTX = true
			return .run { [transactionManifest = state.transactionManifest, addressOfSigner = state.addressOfSigner] send in
				await send(.internal(.signTransactionResult(TaskResult {
					try await profileClient.signTransaction(
						manifest: transactionManifest,
						addressOfSigner: addressOfSigner
					)
				})))
			}

		case let .internal(.signTransactionResult(.success(txid))):
			state.isSigningTX = false
			return .run { [incomingMessageFromBrowser = state.incomingMessageFromBrowser] send in
				await send(.delegate(
					.signedTXAndSubmittedToGateway(
						txid,
						incomingMessageFromBrowser: incomingMessageFromBrowser
					)
				))
			}

		case let .internal(.signTransactionResult(.failure(error))):
			state.isSigningTX = false
			errorQueue.schedule(error)
			return .none

		case .internal(.view(.closeButtonTapped)):
			return .run { send in
				await send(.delegate(.dismissView))
			}

		case .delegate:
			return .none
		}
	}
}

import ComposableArchitecture
import EngineToolkitClient
import ErrorQueue
import Foundation
import Resources
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

			return .run { [request = state.request] send in
				await send(.delegate(
					.signedTXAndSubmittedToGateway(
						txID,
						request: request
					)
				))
			}

		case let .internal(.signTransactionResult(.failure(transactionFailure))):
			state.isSigningTX = false
			errorQueue.schedule(transactionFailure)
			return .none

		case .internal(.view(.closeButtonTapped)):
			return .run { [rejectedRequest = state.request] send in
				await send(.delegate(.rejected(rejectedRequest)))
			}

		case .delegate:
			return .none
		}
	}
}

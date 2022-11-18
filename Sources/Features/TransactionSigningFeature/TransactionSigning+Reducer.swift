import ComposableArchitecture
import EngineToolkitClient
import Foundation
import ProfileClient

// MARK: - TransactionSigning
public struct TransactionSigning: ReducerProtocol {
	@Dependency(\.profileClient) var profileClient
	public init() {}
}

public extension TransactionSigning {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.signTransactionButtonTapped)):
			state.isSigningTX = true
			return .run { [transactionManifest = state.transactionManifest] send in
				await send(.internal(.signTransactionResult(TaskResult {
					try await profileClient.signTransaction(transactionManifest)
				})))
			}

		case let .internal(.signTransactionResult(result)):
			state.isSigningTX = false
			switch result {
			case let .success(txid):
				return .run { [request = state.request] send in
					await send(.delegate(
						.signedTXAndSubmittedToGateway(
							txid,
							request: request
						)
					))
				}
			case let .failure(error):
				state.errorAlert = .init(title: .init("An error ocurred"), message: .init(error.localizedDescription))
			}
			return .none

		case .internal(.view(.errorAlertDismissButtonTapped)):
			state.errorAlert = nil
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

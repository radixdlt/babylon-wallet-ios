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
			return .run { [transactionManifest = state.transactionManifest, addressOfSigner = state.addressOfSigner] send in
				await send(.internal(.signTransactionResult(TaskResult {
					try await profileClient.signTransaction(
						manifest: transactionManifest,
						addressOfSigner: addressOfSigner
					)
				})))
			}

		case let .internal(.signTransactionResult(result)):
			state.isSigningTX = false
			switch result {
			case let .success(txid):
				return .run { [requestFromClient = state.requestFromClient] send in
					await send(.delegate(
						.signedTXAndSubmittedToGateway(
							txid,
							requestFromClient: requestFromClient
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
			return .run { send in
				await send(.delegate(.dismissView))
			}

		case .delegate:
			return .none
		}
	}
}

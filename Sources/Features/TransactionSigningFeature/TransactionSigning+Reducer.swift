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
		case .delegate:
			return .none
		case let .internal(action):
			switch action {
			case .view(.signTransactionButtonTapped):
				state.isSigningTX = true
				return .run { [transactionManifest = state.transactionManifest, addressOfSigner = state.addressOfSigner] send in
					await send(.internal(.signTransactionResult(TaskResult {
						try await profileClient.signTransaction(
							manifest: transactionManifest,
							addressOfSigner: addressOfSigner
						)
					})))
				}

			case let .signTransactionResult(result):
				state.isSigningTX = false
				switch result {
				case let .success(txid):
					return .run { [incomingMessageFromBrowser = state.incomingMessageFromBrowser] send in
						await send(.delegate(
							.signedTXAndSubmittedToGateway(
								txid,
								incomingMessageFromBrowser: incomingMessageFromBrowser
							)
						))
					}
				case let .failure(error):
					state.errorAlert = .init(title: .init("An error ocurred"), message: .init(error.localizedDescription))
				}
				return .none

			case .view(.errorAlertDismissButtonTapped):
				state.errorAlert = nil
				return .none

			case .view(.closeButtonTapped):
				return .run { send in await send(.delegate(.dismissView)) }
			}
		}
	}
}

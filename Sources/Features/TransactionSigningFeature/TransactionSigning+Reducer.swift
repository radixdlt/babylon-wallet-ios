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
		case .view(.signTransaction):
			return .run { [addressOfSigner = state.addressOfSigner, transactionManifest = state.transactionManifest] send in
				let addressLookupResult = Result {
					try profileClient.lookupAccountByAddress(addressOfSigner)
				}
				switch addressLookupResult {
				case let .failure(error as NSError):
					await send(.internal(.addressLookupFailed(error)))
				case let .success(account):
					await send(.internal(.signTransactionResult(TaskResult {
						try await profileClient.signTransaction(account.id, transactionManifest)
					})))
				}
			}
		case let .internal(.addressLookupFailed(error)):
			state.errorAlert = .init(title: .init("An error ocurred"), message: .init(error.localizedDescription))
			return .none
		case let .internal(.signTransactionResult(result)):
			switch result {
			case let .success(txid):
				return .run { [originalDappRequest = state.requestFromDapp] send in
					await send(.delegate(
						.signedTXAndSubmittedToGateway(
							txid,
							originalDappRequest: originalDappRequest
						)
					))
				}
			case let .failure(error):
				state.errorAlert = .init(title: .init("An error ocurred"), message: .init(error.localizedDescription))
			}
			return .none
		case .view(.dismissErrorAlert):
			state.errorAlert = nil
			return .none
		case .delegate:
			return .none
		}
	}
}

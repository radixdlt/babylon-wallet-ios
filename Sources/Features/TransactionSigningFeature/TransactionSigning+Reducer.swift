import ComposableArchitecture
import EngineToolkitClient
import Foundation
import ProfileClient

// MARK: - TransactionSigning
public struct TransactionSigning: ReducerProtocol {
	@Dependency(\.profileClient) var profileClient
}

public extension TransactionSigning {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .signTransaction:
			return .run { [address = state.address, transactionManifest = state.transactionManifest] send in
				let addressLookupResult = Result {
					try profileClient.lookupAccountByAddress(address)
				}
				switch addressLookupResult {
				case let .failure(error as NSError):
					await send(.internal(.system(.addressLookupFailed(error))))
				case let .success(account):
					let result = await TaskResult {
						try await profileClient.signTransaction(account.id, transactionManifest)
					}
					await send(.internal(.user(.signTransactionResult(result))))
				}
			}
		case .internal:
			return .none
		case .coordinate:
			return .none
		}
	}
}

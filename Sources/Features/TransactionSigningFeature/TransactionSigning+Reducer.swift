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
			return .run { [address = state.address, transactionManifest = state.transactionManifest] send in
				let addressLookupResult = Result {
					try profileClient.lookupAccountByAddress(address)
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
		case .internal:
			return .none
		case .delegate:
			return .none
		}
	}
}

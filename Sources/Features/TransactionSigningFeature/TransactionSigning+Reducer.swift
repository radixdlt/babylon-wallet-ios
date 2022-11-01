import ComposableArchitecture
import EngineToolkitClient
import ProfileClient

// MARK: - TransactionSigning
public struct TransactionSigning: ReducerProtocol {
	@Dependency(\.profileClient) var profile
}

public extension TransactionSigning {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .signTransaction:
			return .run { send in
				let result = TaskResult {
					try await profile.signTransaction(state.account.id, state.transactionManifest)
				}
				await send(.internal(.user(.signTransactionResult(result))))
			}
		case .internal:
			return .none
		case .coordinate:
			return .none
		}
	}
}

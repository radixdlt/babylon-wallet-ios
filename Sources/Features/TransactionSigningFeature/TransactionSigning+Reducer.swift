import ComposableArchitecture
import EngineToolkitClient
import GatewayAPI
import ProfileClient

// MARK: - TransactionSigning
public struct TransactionSigning: ReducerProtocol {
	public var account: OnNetwork.Account
	public var transactionManifest: TransactionManifest

	@Dependency(\.profileClient) var profile

	public init(
		account: OnNetwork.Account,
		transactionManifest: TransactionManifest
	) {
		self.account = account
		self.transactionManifest = transactionManifest
	}
}

public extension TransactionSigning {
	public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .signTransaction:
			return .run { send in
				let result = TaskResult {
					try await profile.signTransaction(state.account.id, transactionManifest)
				}
				await send(.internal(.user(.signTransactionResult(result))))
			}
		}
	}
}

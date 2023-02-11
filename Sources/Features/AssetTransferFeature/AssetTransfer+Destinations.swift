import FeaturePrelude
import TransactionSigningFeature

extension AssetTransfer {
	public struct Destinations: ReducerProtocol {
		public enum State: Hashable {
			case transactionSigning(TransactionSigning.State)
		}

		public enum Action: Equatable {
			case transactionSigning(TransactionSigning.Action)
		}

		public var body: some ReducerProtocol<State, Action> {
			Scope(state: /State.transactionSigning, action: /Action.transactionSigning) {
				TransactionSigning()
			}
		}
	}
}

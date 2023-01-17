import FeaturePrelude
import TransactionSigningFeature

public extension AssetTransfer {
	struct Destinations: ReducerProtocol {
		public enum State: Equatable {
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

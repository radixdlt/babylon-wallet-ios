import AssetTransferFeature
import FeaturePrelude

extension AccountDetails {
	public struct Destinations: Sendable, ReducerProtocol, Hashable {
		public enum State: Sendable, Hashable {
			// TODO: case preferences(AccountPreferences.State)
			case transfer(AssetTransfer.State)
		}

		public enum Action: Sendable, Equatable {
			// TODO: case preferences(AccountPreferences.Action)
			case transfer(AssetTransfer.Action)
		}

		public var body: some ReducerProtocol<State, Action> {
			Scope(state: /State.transfer, action: /Action.transfer) {
				AssetTransfer()
			}
		}
	}
}

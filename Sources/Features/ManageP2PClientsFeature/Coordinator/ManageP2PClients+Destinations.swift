import FeaturePrelude
import NewConnectionFeature

extension ManageP2PClients {
	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case newConnection(NewConnection.State)
		}

		public enum Action: Sendable, Equatable {
			case newConnection(NewConnection.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.newConnection, action: /Action.newConnection) {
				NewConnection()
			}
		}
	}
}

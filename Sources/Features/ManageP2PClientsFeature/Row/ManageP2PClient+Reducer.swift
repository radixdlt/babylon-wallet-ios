import FeaturePrelude
import RadixConnectClient

// MARK: - ManageP2PClient
public struct ManageP2PClient: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = ConnectionPassword
		public var id: ID { client.connectionPassword }
		public let client: P2PClient

		public init(
			client: P2PClient
		) {
			self.client = client
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case deleteConnectionButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case deleteConnection
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.radixConnectClient) var radixConnectClient

	public init() {}

	private enum ConnectionUpdateTasksID {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .deleteConnectionButtonTapped:
			return .send(.delegate(.deleteConnection))
		}
	}
}

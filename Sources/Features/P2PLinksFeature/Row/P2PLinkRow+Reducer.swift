import FeaturePrelude
import RadixConnectClient

// MARK: - ManageP2PLink
public struct P2PLinkRow: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = ConnectionPassword
		public var id: ID { link.connectionPassword }
		public let link: P2PLink

		public init(
			link: P2PLink
		) {
			self.link = link
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

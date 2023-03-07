import FeaturePrelude
import P2PConnectivityClient

// MARK: - ManageP2PClient
public struct ManageP2PClient: Sendable, ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.p2pConnectivityClient) var p2pConnectivityClient
	public init() {}
}

extension ManageP2PClient {
	private enum ConnectionUpdateTasksID {}
	public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.deleteConnectionButtonTapped)):
			return .run { send in
				await send(.delegate(.deleteConnection))
			}
		case .delegate:
			return .none
		}
	}
}

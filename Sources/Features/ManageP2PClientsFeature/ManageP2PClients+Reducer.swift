import ComposableArchitecture
import ErrorQueue
import NewConnectionFeature
import P2PConnectivityClient
import Peer
import Profile
import ProfileClient
import SharedModels

// MARK: - ManageP2PClients
public struct ManageP2PClients: Sendable, ReducerProtocol {
	@Dependency(\.p2pConnectivityClient) var p2pConnectivityClient
	@Dependency(\.mainQueue) var mainQueue
	@Dependency(\.errorQueue) var errorQueue
	public init() {}
}

public extension ManageP2PClients {
	var body: some ReducerProtocolOf<Self> {
		Reduce(self.core)
			.forEach(\.connections, action: /Action.child .. Action.ChildAction.connection) {
				ManageP2PClient()
			}
			.ifLet(
				\.newConnection,
				action: /Action.child .. Action.ChildAction.newConnection
			) {
				NewConnection()
					._printChanges()
			}
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.viewAppeared)):
			return .run { send in
				await send(.internal(.system(.loadConnectionsResult(
					TaskResult {
						try await p2pConnectivityClient.getP2PClients().first(where: { !$0.isEmpty }) ?? []
					}
				))))
			}

		case let .internal(.system(.loadConnectionsResult(.success(connectionsFromProfile)))):
			state.connections = .init(uniqueElements: connectionsFromProfile)
			return .none

		case let .internal(.system(.loadConnectionsResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case let .internal(.system(.saveNewConnectionResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case let .internal(.system(.saveNewConnectionResult(.success(newConnection)))):
			state.connections.append(
				P2P.ClientWithConnectionStatus(
					p2pClient: newConnection.client,
					connectionStatus: .connected
				)
			)
			return .none

		case .internal(.view(.dismissButtonTapped)):
			return .run { send in
				await send(.delegate(.dismiss))
			}
		#if DEBUG
		case let .child(.connection(id, .delegate(.sendTestMessage))):
			return .run { send in
				await send(.internal(.system(.sendTestMessageResult(
					TaskResult {
						let msg = "Test"
						try await self.p2pConnectivityClient._sendTestMessage(id, msg)
						return msg
					}
				))))
			}
		#endif // DEBUG

		case let .child(.connection(id, .delegate(.deleteConnection))):
			return .run { send in
				await send(.internal(.system(.deleteConnectionResult(
					TaskResult {
						try await p2pConnectivityClient.deleteP2PClientByID(id)
						return id
					}
				))))
			}

		case let .internal(.system(.deleteConnectionResult(.success(deletedID)))):
			state.connections.remove(id: deletedID)
			return .none

		case let .internal(.system(.deleteConnectionResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case .internal(.system(.sendTestMessageResult(.success(_)))):
			return .none

		case let .internal(.system(.sendTestMessageResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case .internal(.view(.addNewConnectionButtonTapped)):
			state.newConnection = .init()
			return .none

		case let .child(.newConnection(.delegate(.newConnection(connectedClient)))):
			state.newConnection = nil
			return .run { send in
				await send(.internal(.system(.saveNewConnectionResult(
					TaskResult {
						try await p2pConnectivityClient.addP2PClientWithConnection(
							connectedClient,
							false // no need to connect, already connected.
						)
					}.map { connectedClient }
				))))
			}

		case .child(.newConnection(.delegate(.dismiss))):
			state.newConnection = nil
			return .none

		case .child, .delegate:
			return .none
		}
	}
}

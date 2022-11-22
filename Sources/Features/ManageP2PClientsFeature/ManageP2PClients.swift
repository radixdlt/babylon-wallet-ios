import ComposableArchitecture
import ConnectUsingPasswordFeature
import Converse
import ConverseCommon
import ErrorQueue
import InputPasswordFeature
import P2PConnectivityClient
import Profile
import ProfileClient
import SharedModels

// MARK: - ManageP2PClients
public struct ManageP2PClients: ReducerProtocol {
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
				\.inputP2PConnectionPassword,
				action: /Action.child .. Action.ChildAction.inputP2PConnectionPassword
			) {
				InputPassword()
			}
			.ifLet(\.connectUsingPassword, action: /Action.child .. Action.ChildAction.connectUsingPassword) {
				ConnectUsingPassword()
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
			state.connections.append(contentsOf: connectionsFromProfile)
			return .none

		case let .internal(.system(.loadConnectionsResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case let .internal(.system(.successfullyOpenedConnection(connection))):
			return saveNewConnection(state: &state, action: action, connection: connection)

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

		case .internal(.view(.addNewConnectionButtonTapped)):
			state.inputP2PConnectionPassword = .init()
			return .none

		case .internal(.view(.dismissNewConnectionFlowButtonTapped)):
			state.inputP2PConnectionPassword = nil
			return .none

		case let .child(.inputP2PConnectionPassword(.delegate(.connect(password)))):
			return .run { send in
				await send(
					.internal(.system(.initConnectionSecretsResult(
						TaskResult<ConnectionSecrets> {
							try ConnectionSecrets.from(connectionPassword: password)
						}
					)))
				)
			}

		case let .internal(.system(.initConnectionSecretsResult(.success(connectionSecrets)))):
			let connection = Connection.live(connectionSecrets: connectionSecrets)
			state.connectUsingPassword = ConnectUsingPassword.State(connection: connection)
			return .none

		case let .internal(.system(.initConnectionSecretsResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case let .child(.connectUsingPassword(.delegate(.establishConnectionResult(.failure(error))))):
			errorQueue.schedule(error)
			return .none

		case let .child(.connectUsingPassword(.delegate(.establishConnectionResult(.success(openConnection))))):
			return saveNewConnection(state: &state, action: action, connection: openConnection)

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

		case let .internal(.system(.sendTestMessageResult(.success(msgSent)))):
			print("Successfully sent message: '\(msgSent)'")
			return .none

		case let .internal(.system(.sendTestMessageResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case .child, .delegate:
			return .none
		}
	}

	func saveNewConnection(state: inout State, action: Action, connection: Connection) -> EffectTask<Action> {
		state.connectUsingPassword = nil
		state.inputP2PConnectionPassword = nil

		let connectedClient = P2P.ConnectedClient(
			client: .init(
				displayName: "Unknown",
				connectionPassword: connection.getConnectionPassword().data.data
			),
			connection: connection
		)

		return .run { send in
			await send(.internal(.system(.saveNewConnectionResult(
				TaskResult {
					try await p2pConnectivityClient.addConnectedP2PClient(
						connectedClient
					)
				}.map { connectedClient }
			))))
		}
	}
}

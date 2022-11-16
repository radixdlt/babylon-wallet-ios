import BrowserExtensionsConnectivityClient
import ComposableArchitecture
import ConnectUsingPasswordFeature
import Converse
import ConverseCommon
import ErrorQueue
import InputPasswordFeature
import Profile
import ProfileClient

// MARK: - ManageBrowserExtensionConnections
public struct ManageBrowserExtensionConnections: ReducerProtocol {
	@Dependency(\.browserExtensionsConnectivityClient) var browserExtensionsConnectivityClient
	@Dependency(\.mainQueue) var mainQueue
	@Dependency(\.errorQueue) var errorQueue
	public init() {}
}

public extension ManageBrowserExtensionConnections {
	var body: some ReducerProtocolOf<Self> {
		Reduce(self.core)
			.forEach(\.connections, action: /Action.child .. Action.ChildAction.connection) {
				ManageBrowserExtensionConnection()
			}
			.ifLet(
				\.inputBrowserExtensionConnectionPassword,
				action: /Action.child .. Action.ChildAction.inputBrowserExtensionConnectionPassword
			) {
				InputPassword()
			}
			.ifLet(\.connectUsingPassword, action: /Action.child .. Action.ChildAction.connectUsingPassword) {
				ConnectUsingPassword()
			}
			._printChanges()
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.viewAppeared)):
			return .run { send in
				await send(.internal(.system(.loadConnectionsResult(
					TaskResult {
						try await browserExtensionsConnectivityClient.getBrowserExtensionConnections()
					}
				))))
			}

		case let .internal(.system(.loadConnectionsResult(.success(browserConnectionsFromProfile)))):
			state.connections.append(contentsOf: browserConnectionsFromProfile)
			return .none

		case let .internal(.system(.loadConnectionsResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case let .internal(.system(.successfullyOpenedConnectionToBrowser(connection))):
			return saveNewConnection(state: &state, action: action, connection: connection)

		case let .internal(.system(.saveNewConnectionResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case let .internal(.system(.saveNewConnectionResult(.success(newConnection)))):
			state.connections.append(
				BrowserExtensionWithConnectionStatus(
					browserExtensionConnection: newConnection.browserExtensionConnection,
					connectionStatus: .connected
				)
			)
			return .none

		case .internal(.view(.dismissButtonTapped)):
			return .run { send in
				await send(.delegate(.dismiss))
			}

		case .internal(.view(.addNewConnectionButtonTapped)):
			state.inputBrowserExtensionConnectionPassword = .init()
			return .none

		case .internal(.view(.dismissNewConnectionFlowButtonTapped)):
			state.inputBrowserExtensionConnectionPassword = nil
			return .none

		case let .child(.inputBrowserExtensionConnectionPassword(.delegate(.connect(password)))):
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
						try await self.browserExtensionsConnectivityClient._sendTestMessage(id, msg)
						return msg
					}
				))))
			}

		case let .child(.connection(id, .delegate(.deleteConnection))):
			return .run { send in
				await send(.internal(.system(.deleteConnectionResult(
					TaskResult {
						try await browserExtensionsConnectivityClient.deleteBrowserExtensionConnection(id)
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
		state.inputBrowserExtensionConnectionPassword = nil

		let statefulBrowserConnection = StatefulBrowserConnection(
			browserExtensionConnection: .init(
				computerName: "Unknown",
				browserName: "Unknown",
				connectionPassword: connection.getConnectionPassword().data.data
			),
			connection: connection
		)

		return .run { send in
			await send(.internal(.system(.saveNewConnectionResult(
				TaskResult {
					try await browserExtensionsConnectivityClient.addBrowserExtensionConnection(
						statefulBrowserConnection
					)
				}.map { statefulBrowserConnection }
			))))
		}
	}
}

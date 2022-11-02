import BrowserExtensionsConnectivityClient
import ComposableArchitecture
import ConnectUsingPasswordFeature
import Converse
import ConverseCommon
import InputPasswordFeature
import Profile
import ProfileClient

// MARK: - ManageBrowserExtensionConnections
public struct ManageBrowserExtensionConnections: ReducerProtocol {
	@Dependency(\.browserExtensionsConnectivityClient) var browserExtensionsConnectivityClient
	public init() {}
}

public extension ManageBrowserExtensionConnections {
	var body: some ReducerProtocol<State, Action> {
		Reduce(self.core)
			.forEach(\.connections, action: /Action.connection(id:action:)) {
				ManageBrowserExtensionConnection()
			}
			.ifLet(
				\.inputBrowserExtensionConnectionPassword,
				action: /ManageBrowserExtensionConnections.Action.inputBrowserExtensionConnectionPassword
			) {
				InputPassword()
			}
			.ifLet(\.connectUsingPassword, action: /ManageBrowserExtensionConnections.Action.connectUsingPassword) {
				ConnectUsingPassword()
			}
			._printChanges()
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.system(.viewDidAppear)):
			return .run { send in
				await send(.internal(.coordinate(.loadConnections)))
			}

		case .internal(.coordinate(.loadConnections)):
			return .run { send in
				await send(.internal(.coordinate(.loadConnectionsResult(
					TaskResult {
						try browserExtensionsConnectivityClient.getBrowserExtensionConnections()
					}
				))))
			}

		case let .internal(.coordinate(.loadConnectionsResult(.success(browserConnectionsFromProfile)))):
			state.connections.append(contentsOf: browserConnectionsFromProfile)
			return .none

		case let .internal(.coordinate(.loadConnectionsResult(.failure(error)))):
			fatalError(String(describing: error))

		case let .internal(.system(.successfullyOpenedConnectionToBrowser(connection))):
			state.connectUsingPassword = nil
			state.inputBrowserExtensionConnectionPassword = nil

			let newConnection = BrowserExtensionWithConnectionStatus(
				browserExtensionConnection: .init(
					computerName: "Unknown",
					browserName: "Unknown",
					connectionPassword: connection.getConnectionPassword().data.data
				),
				connectionStatus: .connected
			)

			return .run { send in
				await send(.internal(.coordinate(.saveNewConnection(newConnection))))
			}

		case let .internal(.coordinate(.saveNewConnection(newConnection))):
			return .run { send in
				await send(.internal(.coordinate(.saveNewConnectionResult(
					TaskResult {
						try await browserExtensionsConnectivityClient.addBrowserExtensionConnection(
							newConnection.browserExtensionConnection
						)
					}.map { newConnection }
				))))
			}

		case let .internal(.coordinate(.saveNewConnectionResult(.failure(error)))):
			fatalError(String(describing: error))

		case let .internal(.coordinate(.saveNewConnectionResult(.success(newConnection)))):
			state.connections.append(newConnection)
			return .none

		case .internal(.user(.dismiss)):
			return .run { send in
				await send(.coordinate(.dismiss))
			}

		case .internal(.user(.addNewConnection)):
			state.inputBrowserExtensionConnectionPassword = .init()
			return .none

		case .internal(.user(.dismissNewConnectionFlow)):
			state.inputBrowserExtensionConnectionPassword = nil
			return .none

		case let .inputBrowserExtensionConnectionPassword(.delegate(.connect(password))):
			return .run { send in
				await send(
					.internal(.coordinate(.initConnectionSecretsResult(
						TaskResult<ConnectionSecrets> {
							try ConnectionSecrets.from(connectionPassword: password)
						}
					)))
				)
			}

		case let .internal(.coordinate(.initConnectionSecretsResult(.success(connectionSecrets)))):
			let connection = Connection.live(connectionSecrets: connectionSecrets)
			state.connectUsingPassword = ConnectUsingPassword.State(connection: connection)
			return .none

		case let .internal(.coordinate(.initConnectionSecretsResult(.failure(error)))):
			fatalError(String(describing: error))

		case let .connectUsingPassword(.delegate(.establishConnectionResult(.failure(error)))):
			fatalError(String(describing: error))

		case let .connectUsingPassword(.delegate(.establishConnectionResult(.success(openConnection)))):
			return .run { send in
				await send(.internal(.system(.successfullyOpenedConnectionToBrowser(openConnection))))
			}

		case let .connection(id, .delegate(.sendTestMessage)):
			return .run { send in
				await send(.internal(.coordinate(.sendTestMessageResult(
					TaskResult {
						let msg = "Test"
						try await self.browserExtensionsConnectivityClient.sendMessage(id, msg)
						return msg
					}
				))))
			}

		case let .connection(id, .delegate(.deleteConnection)):
			return .run { send in
				await send(.internal(.coordinate(.deleteConnectionResult(
					TaskResult {
						try await browserExtensionsConnectivityClient.deleteBrowserExtensionConnection(id)
						return id
					}
				))))
			}
		case let .internal(.coordinate(.deleteConnectionResult(.success(deletedID)))):
			state.connections.remove(id: deletedID)
			return .none

		case let .internal(.coordinate(.deleteConnectionResult(.failure(error)))):
			print("Failed to delete connection from profile, error: \(String(describing: error))")
			return .none

		case .inputBrowserExtensionConnectionPassword:
			return .none

		case .connectUsingPassword:
			return .none

		case .coordinate:
			return .none

		case let .internal(.coordinate(.sendTestMessageResult(.success(msgSent)))):
			print("Successfully sent message: '\(msgSent)'")
			return .none

		case let .internal(.coordinate(.sendTestMessageResult(.failure(error)))):
			print("Failed to send message, error: \(String(describing: error))")
			return .none

		case .connection(_, .internal(_)):
			return .none
		}
	}
}

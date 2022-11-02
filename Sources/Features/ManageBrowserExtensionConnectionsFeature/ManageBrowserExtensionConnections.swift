import ComposableArchitecture
import ConnectUsingPasswordFeature
import Converse
import ConverseCommon
import InputPasswordFeature
import Profile
import ProfileClient

// MARK: - ManageBrowserExtensionConnections
public struct ManageBrowserExtensionConnections: ReducerProtocol {
	@Dependency(\.profileClient) var profileClient
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
				await send(.internal(.coordinate(.loadConnectionsFromProfile)))
			}

		case .internal(.coordinate(.loadConnectionsFromProfile)):
			return .run { send in
				await send(.internal(.coordinate(.loadConnectionsFromProfileResult(
					TaskResult {
						let connections = try profileClient.getBrowserExtensionConnections()
						return try connections.connections.map { (conn: BrowserExtensionConnection) in
							let password = try ConnectionPassword(data: conn.connectionPassword.data)
							let secrets = try ConnectionSecrets.from(connectionPassword: password)
							return BrowserExtensionConnectionWithState(
								browserExtensionConnection: conn,
								statefulConnection: Connection.live(connectionSecrets: secrets)
							)
						}
					}
				))))
			}

		case let .internal(.coordinate(.loadConnectionsFromProfileResult(.success(browserConnectionsFromProfile)))):
			state.connections.append(contentsOf: browserConnectionsFromProfile)
			return .none

		case let .internal(.coordinate(.loadConnectionsFromProfileResult(.failure(error)))):
			fatalError(String(describing: error))

		case let .internal(.system(.successfullyOpenedConnectionToBrowser(connection))):
			state.connectUsingPassword = nil
			state.inputBrowserExtensionConnectionPassword = nil

			let newConnection = BrowserExtensionConnectionWithState(
				browserExtensionConnection: .init(
					computerName: "Unknown",
					browserName: "Unknown",
					connectionPassword: connection.getConnectionPassword().data.data
				),
				statefulConnection: connection
			)

			return .run { send in
				await send(.internal(.coordinate(.saveNewConnectionInProfile(newConnection))))
			}

		case let .internal(.coordinate(.saveNewConnectionInProfile(newConnection))):
			return .run { send in
				await send(.internal(.coordinate(.saveNewConnectionInProfileResult(
					TaskResult {
						try await profileClient.addBrowserExtensionConnection(newConnection.browserExtensionConnection)
					}.map { newConnection }
				))))
			}

		case let .internal(.coordinate(.saveNewConnectionInProfileResult(.failure(error)))):
			fatalError(String(describing: error))

		case let .internal(.coordinate(.saveNewConnectionInProfileResult(.success(newConnection)))):
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
			fatalError("Send test!")

		case let .connection(id, .delegate(.deleteConnection)):
			return .run { send in
				await send(.internal(.coordinate(.deleteConnectionFromProfileResult(
					TaskResult {
						try await profileClient.deleteBrowserExtensionConnection(id)
						return id
					}
				))))
			}
		case let .internal(.coordinate(.deleteConnectionFromProfileResult(.success(deletedID)))):
			state.connections.remove(id: deletedID)
			return .none

		case let .internal(.coordinate(.deleteConnectionFromProfileResult(.failure(error)))):
			print("Failed to delete connection from profile, error: \(String(describing: error))")
			return .none

		case let .connection(id, .internal(_)):
			return .none

		case .inputBrowserExtensionConnectionPassword:
			return .none

		case .connectUsingPassword:
			return .none

		case .coordinate:
			return .none
		}
	}
}

import ComposableArchitecture
import Converse
import SharedModels

// MARK: - ConnectUsingSecrets
public struct ConnectUsingSecrets: Sendable, ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue
	public init() {}
}

public extension ConnectUsingSecrets {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.appeared)):

			let connection = Connection.live(
				connectionSecrets: state.connectionSecrets
			)

			return .run { send in
				await send(.internal(.system(.establishConnectionResult(
					TaskResult {
						try await connection.establish()
						return connection
					}
				))))
			}

		case let .internal(.system(.establishConnectionResult(.success(connection)))):
			state.connectedConnection = connection
			state.isConnecting = false
			state.isPromptingForName = true
			return .none

		case .internal(.view(.confirmNameButtonTapped)):
			guard let connectedConnection = state.connectedConnection else {
				// invalid state
				return .none
			}

			let connectedClient = P2P.ConnectedClient(
				client: .init(
					displayName: state.nameOfConnection.trimmed(),
					connectionPassword: state.connectionSecrets.connectionPassword.data.data
				),
				connection: connectedConnection
			)

			return .run { send in
				await send(.delegate(.connected(connectedClient)))
			}

		case let .internal(.view(.nameOfConnectionChanged(connectionName))):
			state.nameOfConnection = connectionName
			return .none

		case let .internal(.system(.establishConnectionResult(.failure(error)))):
			errorQueue.schedule(error)
			state.isConnecting = false
			return .none

		case .delegate:
			return .none
		}
	}
}

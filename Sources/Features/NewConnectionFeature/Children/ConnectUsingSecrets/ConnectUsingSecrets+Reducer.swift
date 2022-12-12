import ComposableArchitecture
import Converse
import SharedModels

// MARK: - ConnectUsingSecrets
public struct ConnectUsingSecrets: Sendable, ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.mainQueue) var mainQueue
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

				try await self.mainQueue.sleep(for: .seconds(0.5))
				await send(.internal(.system(.focusTextField(.connectionName))))
			}

		case let .internal(.system(.establishConnectionResult(.success(connection)))):
			state.newConnection = connection
			state.isConnecting = false
			state.isPromptingForName = true

			return .none
		case let .internal(.view(.textFieldFocused(focus))):
			return .run { send in
				try? await self.mainQueue.sleep(for: .seconds(0.5))
				await send(.internal(.system(.focusTextField(focus))))
			}

		case let .internal(.system(.focusTextField(focus))):
			state.focusedField = focus
			return .none

		case .internal(.view(.confirmNameButtonTapped)):
			guard let newConnection = state.newConnection else {
				// invalid state
				return .none
			}

			let connectedClient = P2P.ConnectionForClient(
				client: .init(
					displayName: state.nameOfConnection.trimmed(),
					connectionPassword: state.connectionSecrets.connectionPassword.data.data
				),
				connection: newConnection
			)

			return .run { send in
				await send(.internal(.view(.textFieldFocused(nil))))
				await send(.delegate(.connected(connectedClient)))
			}

		case let .internal(.view(.nameOfConnectionChanged(connectionName))):
			state.nameOfConnection = connectionName
			state.isNameValid = !connectionName.trimmed().isEmpty
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

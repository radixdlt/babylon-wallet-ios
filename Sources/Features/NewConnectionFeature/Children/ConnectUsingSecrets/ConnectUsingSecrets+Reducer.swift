import ComposableArchitecture
import P2PConnection
import P2PModels
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
			return .run { [connectionPassword = state.connectionSecrets.connectionPassword] send in
				await send(.internal(.system(.establishConnectionResult(
					TaskResult {
						try await P2PConnections.shared.add(
							connectionPassword: connectionPassword, autoconnect: true
						)
					}
				))))

				try await self.mainQueue.sleep(for: .seconds(0.5))
				await send(.internal(.system(.focusTextField(.connectionName))))
			}

		case let .internal(.system(.establishConnectionResult(.success(idOfNewConnection)))):
			state.idOfNewConnection = idOfNewConnection
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
			// determines if we are indeed connected...
			guard let _ = state.idOfNewConnection else {
				// invalid state
				return .none
			}

			let clientWithConnectionStatus = P2P.ClientWithConnectionStatus(
				p2pClient: .init(
					connectionPassword: state.connectionSecrets.connectionPassword,
					displayName: state.nameOfConnection.trimmed()
				),
				connectionStatus: .connected
			)

			return .run { send in
				await send(.internal(.view(.textFieldFocused(nil))))
				await send(.delegate(.connected(clientWithConnectionStatus)))
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

import ComposableArchitecture
import Resources

// MARK: - NewConnection
public struct NewConnection: ReducerProtocol {
	public init() {}
}

public extension NewConnection {
	var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifCaseLet(/NewConnection.State.scanQR, action: /NewConnection.Action.scanQR) {
				ScanQR()
			}
			.ifCaseLet(/NewConnection.State.connectUsingSecrets, action: /NewConnection.Action.connectUsingSecrets) {
				ConnectUsingSecrets()
			}
	}

	func core(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.appeared)):
			return .none

		case .internal(.view(.dismissButtonTapped)):
			switch state {
			case .scanQR:
				return .run { send in
					await send(.delegate(.dismiss))
				}
			case let .connectUsingSecrets(connectUsingSecrets):
				guard let connection = connectUsingSecrets.connectedConnection else {
					return .run { send in
						await send(.delegate(.dismiss))
					}
				}
				return body.reduce(
					into: &state,
					action: .connectUsingSecrets(.delegate(.connected(
						.init(
							client: .init(
								displayName: L10n.NewConnection.defaultNameOfConnection,
								connectionPassword: connectUsingSecrets.connectionSecrets.connectionPassword.data.data
							),
							connection: connection
						)
					)))
				)
			}

		case let .scanQR(.delegate(.connectionSecretsFromScannedQR(connectionSecrets))):
			state = .connectUsingSecrets(.init(connectionSecrets: connectionSecrets))
			return .none

		case let .connectUsingSecrets(.delegate(.connected(connection))):
			return .run { send in
				await send(.delegate(.newConnection(connection)))
			}

		case .delegate:
			return .none
		case .scanQR:
			return .none
		case .connectUsingSecrets:
			return .none
		}
	}
}

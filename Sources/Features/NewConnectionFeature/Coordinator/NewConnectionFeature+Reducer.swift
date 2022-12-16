import ComposableArchitecture
import P2PConnectivityClient
import Peer
import Resources

// MARK: - NewConnection
public struct NewConnection: Sendable, ReducerProtocol {
	public init() {}
}

public extension NewConnection {
	@ReducerBuilderOf<Self>
	var body: some ReducerProtocolOf<Self> {
		Reduce(core)

		EmptyReducer()
			.ifCaseLet(/State.localNetworkAuthorization, action: /Action.child .. Action.ChildAction.localNetworkAuthorization) {
				LocalNetworkAuthorization()
			}
			.ifCaseLet(/State.scanQR, action: /Action.child .. Action.ChildAction.scanQR) {
				ScanQR()
			}
			.ifCaseLet(/State.connectUsingSecrets, action: /Action.child .. Action.ChildAction.connectUsingSecrets) {
				ConnectUsingSecrets()
			}
	}

	func core(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.dismissButtonTapped)):
			switch state {
			case .localNetworkAuthorization, .scanQR:
				return .run { send in
					await send(.delegate(.dismiss))
				}
			case let .connectUsingSecrets(connectUsingSecrets):
				guard let newPeer = connectUsingSecrets.newPeer else {
					return .run { send in
						await send(.delegate(.dismiss))
					}
				}
				return body.reduce(
					into: &state,
					action: .child(.connectUsingSecrets(.delegate(.connected(
						.init(
							client: .init(
								displayName: L10n.NewConnection.defaultNameOfConnection,
								connectionPassword: connectUsingSecrets.connectionSecrets.connectionPassword.data.data
							),
							peer: newPeer
						)
					))))
				)
			}

		case let .child(.localNetworkAuthorization(.delegate(.localNetworkAuthorizationResponse(isAuthorized)))):
			if isAuthorized {
				state = .scanQR(.init())
				return .none
			} else {
				return .run { send in await send(.delegate(.dismiss)) }
			}

		case let .child(.scanQR(.delegate(.connectionSecretsFromScannedQR(connectionSecrets)))):
			state = .connectUsingSecrets(.init(connectionSecrets: connectionSecrets))
			return .none

		case let .child(.connectUsingSecrets(.delegate(.connected(connection)))):
			return .run { send in
				await send(.delegate(.newConnection(connection)))
			}

		case .child, .delegate:
			return .none
		}
	}
}

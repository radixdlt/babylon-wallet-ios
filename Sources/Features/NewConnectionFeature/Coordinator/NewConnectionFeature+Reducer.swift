import ComposableArchitecture
import P2PConnection
import P2PConnectivityClient
import Resources

// MARK: - NewConnection
public struct NewConnection: Sendable, ReducerProtocol {
	public init() {}
}

public extension NewConnection {
	@ReducerBuilderOf<Self>
	var body: some ReducerProtocolOf<Self> {
		EmptyReducer()
			.ifCaseLet(/State.localNetworkPermission, action: /Action.child .. Action.ChildAction.localNetworkPermission) {
				LocalNetworkPermission()
			}
			.ifCaseLet(/State.cameraPermission, action: /Action.child .. Action.ChildAction.cameraPermission) {
				CameraPermission()
			}
			.ifCaseLet(/State.scanQR, action: /Action.child .. Action.ChildAction.scanQR) {
				ScanQR()
			}
			.ifCaseLet(/State.connectUsingSecrets, action: /Action.child .. Action.ChildAction.connectUsingSecrets) {
				ConnectUsingSecrets()
			}

		Reduce(core)
	}

	func core(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.dismissButtonTapped)):
			switch state {
			case .localNetworkPermission, .cameraPermission, .scanQR:
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

		case let .child(.localNetworkPermission(.delegate(.permissionResponse(allowed)))):
			if allowed {
				#if os(iOS)
				state = .cameraPermission(.init())
				#elseif os(macOS)
				state = .scanQR(.init())
				#endif
				return .none
			} else {
				return .run { send in await send(.delegate(.dismiss)) }
			}

		case let .child(.cameraPermission(.delegate(.permissionResponse(allowed)))):
			if allowed {
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

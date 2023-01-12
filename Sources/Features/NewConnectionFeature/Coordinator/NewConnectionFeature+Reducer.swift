import FeaturePrelude
import P2PConnectivityClient

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
				// checks if we are indded connected
				guard let _ = connectUsingSecrets.idOfNewConnection else {
					return .run { send in
						await send(.delegate(.dismiss))
					}
				}
				return body.reduce(
					into: &state,
					action: .child(.connectUsingSecrets(.delegate(.connected(
						.init(
							p2pClient: .init(
								connectionPassword: connectUsingSecrets.connectionSecrets.connectionPassword,
								displayName: L10n.NewConnection.defaultNameOfConnection
							),
							connectionStatus: .connected
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

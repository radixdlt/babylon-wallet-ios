import FeaturePrelude
import P2PConnectivityClient

// MARK: - NewConnection
public struct NewConnection: Sendable, ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
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
				return .none
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

		case let .child(.scanQR(.delegate(.connectionSecretsFromScannedQR(connectionPassword)))):
			state = .connectUsingSecrets(.init(connectionSecrets: connectionPassword))
			return .none

		case let .child(.connectUsingSecrets(.delegate(.connected(client)))):
			return .run { send in
				await send(.delegate(.newConnection(client)))
			}

		case .child, .delegate:
			return .none
		}
	}
}

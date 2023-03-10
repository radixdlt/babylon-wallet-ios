import FeaturePrelude
import RadixConnectClient

// MARK: - NewConnection
public struct NewConnection: Sendable, FeatureReducer {
	public enum State: Sendable, Hashable {
		case localNetworkPermission(LocalNetworkPermission.State)
		case cameraPermission(CameraPermission.State)
		case scanQR(ScanQR.State)
		case connectUsingSecrets(ConnectUsingSecrets.State)

		public init() {
			self = .localNetworkPermission(.init())
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case cameraPermission(CameraPermission.Action)
		case localNetworkPermission(LocalNetworkPermission.Action)
		case scanQR(ScanQR.Action)
		case connectUsingSecrets(ConnectUsingSecrets.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
		case newConnection(P2PLink)
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifCaseLet(/State.localNetworkPermission, action: /Action.child .. ChildAction.localNetworkPermission) {
				LocalNetworkPermission()
			}
			.ifCaseLet(/State.cameraPermission, action: /Action.child .. ChildAction.cameraPermission) {
				CameraPermission()
			}
			.ifCaseLet(/State.scanQR, action: /Action.child .. ChildAction.scanQR) {
				ScanQR()
			}
			.ifCaseLet(/State.connectUsingSecrets, action: /Action.child .. ChildAction.connectUsingSecrets) {
				ConnectUsingSecrets()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeButtonTapped:
			switch state {
			case .localNetworkPermission, .cameraPermission, .scanQR:
				return .send(.delegate(.dismiss))
			case let .connectUsingSecrets(connectUsingSecrets):
				return .send(
					.child(.connectUsingSecrets(.delegate(.connected(
						.init(connectionPassword: connectUsingSecrets.connectionPassword,
						      displayName: L10n.NewConnection.defaultNameOfConnection)
					))))
				)
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .connectUsingSecrets(.view(.task)):
			return .none

		case let .localNetworkPermission(.delegate(.permissionResponse(allowed))):
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

		case let .cameraPermission(.delegate(.permissionResponse(allowed))):
			if allowed {
				state = .scanQR(.init())
				return .none
			} else {
				return .run { send in await send(.delegate(.dismiss)) }
			}

		case let .scanQR(.delegate(.connectionSecretsFromScannedQR(connectionSecrets))):
			state = .connectUsingSecrets(.init(connectionPassword: connectionSecrets))
			return .none

		case let .connectUsingSecrets(.delegate(.connected(connection))):
			return .send(.delegate(.newConnection(connection)))

		default:
			return .none
		}
	}
}

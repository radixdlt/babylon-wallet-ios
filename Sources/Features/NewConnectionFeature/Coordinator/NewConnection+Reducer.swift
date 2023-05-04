import FeaturePrelude
import RadixConnectClient
import ScanQRFeature

// MARK: - NewConnection
public struct NewConnection: Sendable, FeatureReducer {
	public enum State: Sendable, Hashable {
		case localNetworkPermission(LocalNetworkPermission.State)
		case scanQR(ScanQRCoordinator.State)
		case connectUsingSecrets(ConnectUsingSecrets.State)

		public init() {
			self = .localNetworkPermission(.init())
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case localNetworkPermission(LocalNetworkPermission.Action)
		case scanQR(ScanQRCoordinator.Action)
		case connectUsingSecrets(ConnectUsingSecrets.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
		case newConnection(P2PLink)
	}

	public enum InternalAction: Sendable, Equatable {
		case connectionPasswordFromStringResult(TaskResult<ConnectionPassword>)
	}

	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifCaseLet(/State.localNetworkPermission, action: /Action.child .. ChildAction.localNetworkPermission) {
				LocalNetworkPermission()
			}

			.ifCaseLet(/State.scanQR, action: /Action.child .. ChildAction.scanQR) {
				ScanQRCoordinator()
			}
			.ifCaseLet(/State.connectUsingSecrets, action: /Action.child .. ChildAction.connectUsingSecrets) {
				ConnectUsingSecrets()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeButtonTapped:
			switch state {
			case .localNetworkPermission, .scanQR:
				return .send(.delegate(.dismiss))
			case let .connectUsingSecrets(connectUsingSecrets):
				return .send(
					.child(.connectUsingSecrets(.delegate(.connected(
						.init(connectionPassword: connectUsingSecrets.connectionPassword,
						      displayName: L10n.NewConnection.connectionDefaultName)
					))))
				)
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .connectionPasswordFromStringResult(.success(ConnectionPassword)):
			state = .connectUsingSecrets(.init(connectionPassword: ConnectionPassword))
			return .none
		case let .connectionPasswordFromStringResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .localNetworkPermission(.delegate(.permissionResponse(allowed))):
			if allowed {
				state = .scanQR(.init(scanInstructions: L10n.NewConnection.subtitle))
				return .none
			} else {
				return .run { send in await send(.delegate(.dismiss)) }
			}

		case let .scanQR(.delegate(.scanned(qrString))):
			return .run { send in
				await send(.internal(.connectionPasswordFromStringResult(TaskResult {
					try ConnectionPassword(.init(hex: qrString))
				})))
			}

		case let .connectUsingSecrets(.delegate(.connected(connection))):
			return .send(.delegate(.newConnection(connection)))

		default:
			return .none
		}
	}
}

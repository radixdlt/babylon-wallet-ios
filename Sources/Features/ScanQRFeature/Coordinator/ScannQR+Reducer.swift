import FeaturePrelude

// MARK: - ScannQR
public struct ScannQR: Sendable, FeatureReducer {
	public enum State: Sendable, Hashable {
		case cameraPermission(CameraPermission.State)
		case doScanQR(DoScanQR.State)

		public init() {
			self = .cameraPermission(.init())
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case cameraPermission(CameraPermission.Action)
		case doScanQR(DoScanQR.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
		case scanned(String)
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)

			.ifCaseLet(/State.cameraPermission, action: /Action.child .. ChildAction.cameraPermission) {
				CameraPermission()
			}
			.ifCaseLet(/State.doScanQR, action: /Action.child .. ChildAction.doScanQR) {
				DoScanQR()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeButtonTapped:
			return .send(.delegate(.dismiss))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .cameraPermission(.delegate(.permissionResponse(allowed))):
			if allowed {
				state = .doScanQR(.init())
				return .none
			} else {
				return .run { send in await send(.delegate(.dismiss)) }
			}

		case let .doScanQR(.delegate(.scanned(content))):
			return .send(.delegate(.scanned(content)))

		default:
			return .none
		}
	}
}

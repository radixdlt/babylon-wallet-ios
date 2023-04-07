import FeaturePrelude

// MARK: - ScanQRCoordinator
public struct ScanQRCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Step: Sendable, Hashable {
			case cameraPermission(CameraPermission.State)
			case scanQR(ScanQR.State)

			public init() {
				self = .cameraPermission(.init())
			}
		}

		public var step: Step
		public let scanInstructions: String
		public init(
			scanInstructions: String,
			step: Step = .init()
		) {
			self.scanInstructions = scanInstructions
			self.step = step
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case cameraPermission(CameraPermission.Action)
		case scanQR(ScanQR.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
		case scanned(String)
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)

		Scope(state: \.step, action: /.self) {
			Scope(
				state: /State.Step.cameraPermission,
				action: /Action.child .. ChildAction.cameraPermission
			) {
				CameraPermission()
			}
			Scope(
				state: /State.Step.scanQR,
				action: /Action.child .. ChildAction.scanQR
			) {
				ScanQR()
			}
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
				state.step = .scanQR(.init(scanInstructions: state.scanInstructions))
				return .none
			} else {
				return .run { send in await send(.delegate(.dismiss)) }
			}

		case let .scanQR(.delegate(.scanned(content))):
			return .send(.delegate(.scanned(content)))

		default:
			return .none
		}
	}
}

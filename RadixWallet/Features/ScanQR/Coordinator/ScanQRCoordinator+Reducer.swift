import ComposableArchitecture
import SwiftUI

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
		public let kind: ScanQR.Kind
		public init(
			kind: ScanQR.Kind,
			step: Step = .init()
		) {
			self.kind = kind
			self.step = step
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case proceedWithScan
	}

	public enum ChildAction: Sendable, Equatable {
		case cameraPermission(CameraPermission.Action)
		case scanQR(ScanQR.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
		case scanned(String)
	}

	@Dependency(\.continuousClock) var clock
	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.step, action: /.self) {
			Scope(state: /State.Step.cameraPermission, action: /Action.child .. ChildAction.cameraPermission) {
				CameraPermission()
			}
			Scope(state: /State.Step.scanQR, action: /Action.child .. ChildAction.scanQR) {
				ScanQR()
			}
		}

		Reduce(core)
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .proceedWithScan:
			state.step = .scanQR(.init(kind: state.kind))
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .cameraPermission(.delegate(.permissionResponse(allowed))):
			if allowed {
				.run { send in
					// FIXME: temporary hack to try to solve some navigation issues
					try await clock.sleep(for: .milliseconds(900))
					await send(.internal(.proceedWithScan))
				}
			} else {
				.send(.delegate(.dismiss))
			}

		case let .scanQR(.delegate(.scanned(content))):
			.send(.delegate(.scanned(content)))

		default:
			.none
		}
	}
}

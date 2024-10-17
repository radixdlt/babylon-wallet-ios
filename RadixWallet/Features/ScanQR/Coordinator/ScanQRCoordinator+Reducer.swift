import ComposableArchitecture
import SwiftUI

// MARK: - ScanQRCoordinator
struct ScanQRCoordinator: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		enum Step: Sendable, Hashable {
			case cameraPermission(CameraPermission.State)
			case scanQR(ScanQR.State)

			init() {
				self = .cameraPermission(.init())
			}
		}

		var step: Step
		let kind: ScanQR.Kind
		init(
			kind: ScanQR.Kind,
			step: Step = .init()
		) {
			self.kind = kind
			self.step = step
		}
	}

	enum InternalAction: Sendable, Equatable {
		case proceedWithScan
	}

	enum ChildAction: Sendable, Equatable {
		case cameraPermission(CameraPermission.Action)
		case scanQR(ScanQR.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case dismiss
		case scanned(String)
	}

	@Dependency(\.continuousClock) var clock
	init() {}

	var body: some ReducerOf<Self> {
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

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .proceedWithScan:
			state.step = .scanQR(.init(kind: state.kind))
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
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

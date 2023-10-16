import ComposableArchitecture
import SwiftUI

// MARK: - CameraPermission
public struct CameraPermission: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		@PresentationState
		var permissionDeniedAlert: AlertState<ViewAction.PermissionDeniedAlertAction>? = nil

		init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		public enum PermissionDeniedAlertAction: Sendable, Equatable {
			case cancelButtonTapped
			case openSettingsButtonTapped
		}

		case appeared
		case permissionDeniedAlert(PresentationAction<PermissionDeniedAlertAction>)
	}

	public enum InternalAction: Sendable, Equatable {
		case displayPermissionDeniedAlert
	}

	public enum DelegateAction: Sendable, Equatable {
		case permissionResponse(Bool)
	}

	@Dependency(\.cameraPermissionClient) var cameraPermissionClient
	@Dependency(\.openURL) var openURL

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$permissionDeniedAlert, action: /Action.view .. ViewAction.permissionDeniedAlert)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			.run { send in
				let allowed = await cameraPermissionClient.getCameraAccess()
				if allowed {
					await send(.delegate(.permissionResponse(true)))
				} else {
					await send(.internal(.displayPermissionDeniedAlert))
				}
			}
		case let .permissionDeniedAlert(.presented(action)):
			switch action {
			case .cancelButtonTapped:
				.send(.delegate(.permissionResponse(false)))
			case .openSettingsButtonTapped:
				.run { send in
					await send(.delegate(.permissionResponse(false)))
					await openURL(URL(string: UIApplication.openSettingsURLString)!)
				}
			}
		case .permissionDeniedAlert:
			.none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .displayPermissionDeniedAlert:
			state.permissionDeniedAlert = .init(
				title: { TextState(L10n.LinkedConnectors.CameraPermissionDeniedAlert.title) },
				actions: {
					ButtonState(
						role: .cancel,
						action: .send(.cancelButtonTapped),
						label: { TextState(L10n.Common.cancel) }
					)
					ButtonState(
						role: .none,
						action: .send(.openSettingsButtonTapped),
						label: { TextState(L10n.Common.systemSettings) }
					)
				},
				message: { TextState(L10n.LinkedConnectors.CameraPermissionDeniedAlert.message) }
			)
			return .none
		}
	}
}

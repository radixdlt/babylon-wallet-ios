import CameraPermissionClient
import FeaturePrelude
#if os(iOS)
import class UIKit.UIApplication
#endif

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

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$permissionDeniedAlert, action: /Action.view .. ViewAction.permissionDeniedAlert)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { send in
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
				return .send(.delegate(.permissionResponse(false)))
			case .openSettingsButtonTapped:
				return .run { send in
					await send(.delegate(.permissionResponse(false)))
					#if os(iOS)
					await openURL(URL(string: UIApplication.openSettingsURLString)!)
					#endif
				}
			}
		case .permissionDeniedAlert:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case .displayPermissionDeniedAlert:
			state.permissionDeniedAlert = .init(
				title: { TextState(L10n.NewConnection.CameraPermission.DeniedAlert.title) },
				actions: {
					ButtonState(
						role: .cancel,
						action: .send(.cancelButtonTapped),
						label: { TextState(L10n.NewConnection.CameraPermission.DeniedAlert.cancelButtonTitle) }
					)
					ButtonState(
						role: .none,
						action: .send(.openSettingsButtonTapped),
						label: { TextState(L10n.NewConnection.CameraPermission.DeniedAlert.settingsButtonTitle) }
					)
				},
				message: { TextState(L10n.NewConnection.CameraPermission.DeniedAlert.message) }
			)
			return .none
		}
	}
}

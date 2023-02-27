import CameraPermissionClient
import FeaturePrelude
#if os(iOS)
import class UIKit.UIApplication
#endif

// MARK: - CameraPermission
public struct CameraPermission: Sendable, ReducerProtocol {
	@Dependency(\.cameraPermissionClient) var cameraPermissionClient
	@Dependency(\.openURL) var openURL

	public init() {}
}

extension CameraPermission {
	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$permissionDeniedAlert, action: /Action.internal .. Action.InternalAction.view .. Action.ViewAction.permissionDeniedAlert)
	}

	public func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.appeared)):
			return .run { send in
				let allowed = await cameraPermissionClient.getCameraAccess()
				if allowed {
					await send(.delegate(.permissionResponse(true)))
				} else {
					await send(.internal(.system(.displayPermissionDeniedAlert)))
				}
			}

		case .internal(.system(.displayPermissionDeniedAlert)):
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

		case let .internal(.view(.permissionDeniedAlert(.presented(action)))):
			switch action {
			case .cancelButtonTapped:
				return .run { send in
					await send(.delegate(.permissionResponse(false)))
				}
			case .openSettingsButtonTapped:
				return .run { send in
					await send(.delegate(.permissionResponse(false)))
					#if os(iOS)
					await openURL(URL(string: UIApplication.openSettingsURLString)!)
					#endif
				}
			}
		case .internal(.view(.permissionDeniedAlert)):
			return .none

		case .delegate:
			return .none
		}
	}
}

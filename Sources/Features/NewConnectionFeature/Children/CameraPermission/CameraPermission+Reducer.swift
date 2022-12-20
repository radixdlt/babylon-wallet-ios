import CameraPermissionClient
import Common
import ComposableArchitecture
#if os(iOS)
import class UIKit.UIApplication
#endif

// MARK: - CameraPermission
public struct CameraPermission: Sendable, ReducerProtocol {
	@Dependency(\.cameraPermissionClient) var cameraPermissionClient
	@Dependency(\.openURL) var openURL

	public init() {}
}

public extension CameraPermission {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
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

		case let .internal(.view(.permissionDeniedAlert(action))):
			state.permissionDeniedAlert = nil
			switch action {
			case .dismissed, .cancelButtonTapped:
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

		case .delegate:
			return .none
		}
	}
}

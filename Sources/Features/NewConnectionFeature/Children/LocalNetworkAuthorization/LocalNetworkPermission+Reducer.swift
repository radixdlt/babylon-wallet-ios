import FeaturePrelude
import P2PConnectivityClient
#if os(iOS)
import class UIKit.UIApplication
#endif

// MARK: - LocalNetworkPermission
public struct LocalNetworkPermission: Sendable, ReducerProtocol {
	@Dependency(\.p2pConnectivityClient) var p2pConnectivityClient
	@Dependency(\.openURL) var openURL

	public init() {}
}

extension LocalNetworkPermission {
	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$permissionDeniedAlert, action: /Action.internal .. Action.InternalAction.view .. Action.ViewAction.permissionDeniedAlert)
	}

	public func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.appeared)):
			return .run { send in
				let allowed = await p2pConnectivityClient.getLocalNetworkAccess()
				if allowed {
					await send(.delegate(.permissionResponse(true)))
				} else {
					await send(.internal(.system(.displayPermissionDeniedAlert)))
				}
			}

		case .internal(.system(.displayPermissionDeniedAlert)):
			state.permissionDeniedAlert = .init(
				title: { TextState(L10n.NewConnection.LocalNetworkPermission.DeniedAlert.title) },
				actions: {
					ButtonState(
						role: .cancel,
						action: .send(.cancelButtonTapped),
						label: { TextState(L10n.NewConnection.LocalNetworkPermission.DeniedAlert.cancelButtonTitle) }
					)
					ButtonState(
						role: .none,
						action: .send(.openSettingsButtonTapped),
						label: { TextState(L10n.NewConnection.LocalNetworkPermission.DeniedAlert.settingsButtonTitle) }
					)
				},
				message: { TextState(L10n.NewConnection.LocalNetworkPermission.DeniedAlert.message) }
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

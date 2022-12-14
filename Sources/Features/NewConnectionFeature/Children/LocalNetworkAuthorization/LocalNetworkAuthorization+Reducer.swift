import Common
import ComposableArchitecture
import P2PConnectivityClient
#if os(iOS)
import class UIKit.UIApplication
#endif

// MARK: - LocalNetworkAuthorization
public struct LocalNetworkAuthorization: Sendable, ReducerProtocol {
	@Dependency(\.p2pConnectivityClient) var p2pConnectivityClient
	@Dependency(\.openURL) var openURL

	public init() {}
}

public extension LocalNetworkAuthorization {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.appeared)):
			return .run { send in
				let isLocalNetworkAuthorized = await p2pConnectivityClient.getLocalNetworkAuthorization()
				if isLocalNetworkAuthorized {
					await send(.delegate(.localNetworkAuthorizationResponse(true)))
				} else {
					await send(.internal(.system(.displayAuthorizationDeniedAlert)))
				}
			}

		case .internal(.system(.displayAuthorizationDeniedAlert)):
			state.authorizationDeniedAlert = .init(
				title: { TextState(L10n.NewConnection.LocalNetworkAuthorization.DeniedAlert.title) },
				actions: {
					ButtonState(
						role: .cancel,
						action: .send(.cancelButtonTapped),
						label: { TextState(L10n.NewConnection.LocalNetworkAuthorization.DeniedAlert.cancelButtonTitle) }
					)
					ButtonState(
						role: .none,
						action: .send(.openSettingsButtonTapped),
						label: { TextState(L10n.NewConnection.LocalNetworkAuthorization.DeniedAlert.settingsButtonTitle) }
					)
				},
				message: { TextState(L10n.NewConnection.LocalNetworkAuthorization.DeniedAlert.message) }
			)
			return .none

		case let .internal(.view(.authorizationDeniedAlert(action))):
			state.authorizationDeniedAlert = nil
			switch action {
			case .dismissed:
				return .none
			case .cancelButtonTapped:
				return .run { send in
					await send(.delegate(.localNetworkAuthorizationResponse(false)))
				}
			case .openSettingsButtonTapped:
				return .run { send in
					await send(.delegate(.localNetworkAuthorizationResponse(false)))
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

import Common
import ComposableArchitecture
import P2PConnectivityClient
import UIKit

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
				title: { TextState("Permission Denied") },
				actions: {
					ButtonState(
						role: .cancel,
						action: .send(.cancelButtonTapped),
						label: { TextState("Cancel") }
					)
					ButtonState(
						role: .none,
						action: .send(.openSettingsButtonTapped),
						label: { TextState("Settings") }
					)
				},
				message: { TextState("Local Network access is required to link to connector.") }
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
					await openURL(URL(string: UIApplication.openSettingsURLString)!)
				}
			}

		case .delegate:
			return .none
		}
	}
}

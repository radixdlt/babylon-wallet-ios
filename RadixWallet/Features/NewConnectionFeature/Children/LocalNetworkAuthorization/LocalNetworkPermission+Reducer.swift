import ComposableArchitecture
import SwiftUI

// MARK: - LocalNetworkPermission
struct LocalNetworkPermission: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		@PresentationState
		var permissionDeniedAlert: AlertState<ViewAction.PermissionDeniedAlertAction>? = nil

		init() {}
	}

	enum ViewAction: Sendable, Equatable {
		enum PermissionDeniedAlertAction: Sendable, Equatable {
			case cancelButtonTapped
			case openSettingsButtonTapped
		}

		case appeared
		case permissionDeniedAlert(PresentationAction<PermissionDeniedAlertAction>)
	}

	enum InternalAction: Sendable, Equatable {
		case displayPermissionDeniedAlert
	}

	enum DelegateAction: Sendable, Equatable {
		case permissionResponse(Bool)
	}

	@Dependency(\.radixConnectClient) var radixConnectClient
	@Dependency(\.openURL) var openURL

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$permissionDeniedAlert, action: /Action.view .. ViewAction.permissionDeniedAlert)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			.run { send in
				let allowed = await radixConnectClient.getLocalNetworkAccess()
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

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .displayPermissionDeniedAlert:
			state.permissionDeniedAlert = .init(
				title: { TextState(L10n.LinkedConnectors.LocalNetworkPermissionDeniedAlert.title) },
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
				message: { TextState(L10n.LinkedConnectors.LocalNetworkPermissionDeniedAlert.message) }
			)
			return .none
		}
	}
}

import ComposableArchitecture
import P2PConnectivityClient
import Resources
import UIKit

// MARK: - NewConnection
public struct NewConnection: Sendable, ReducerProtocol {
	@Dependency(\.p2pConnectivityClient) var p2pConnectivityClient
	@Dependency(\.openURL) var openURL

	public init() {}
}

public extension NewConnection {
	@ReducerBuilderOf<Self>
	var body: some ReducerProtocolOf<Self> {
		Reduce(core)

		Scope(state: \.route, action: /.self) {
			EmptyReducer()
				.ifCaseLet(/NewConnection.State.Route.scanQR, action: /NewConnection.Action.scanQR) {
					ScanQR()
				}
				.ifCaseLet(/NewConnection.State.Route.connectUsingSecrets, action: /NewConnection.Action.connectUsingSecrets) {
					ConnectUsingSecrets()
				}
		}
	}

	func core(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.appeared)):
			return .run { send in
				let isLocalNetworkAuthorized = await p2pConnectivityClient.getLocalNetworkAuthorization()
				if !isLocalNetworkAuthorized {
					await send(.internal(.system(.displayLocalAuthorizationDeniedAlert)))
				}
			}

		case .internal(.system(.displayLocalAuthorizationDeniedAlert)):
			state.localAuthorizationDeniedAlert = .init(
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

		case let .internal(.view(.localAuthorizationDeniedAlert(action))):
			state.localAuthorizationDeniedAlert = nil
			switch action {
			case .cancelButtonTapped:
				return .run { send in
					await send(.delegate(.dismiss))
				}
			case .openSettingsButtonTapped:
				return .run { _ in
					await openURL(URL(string: UIApplication.openSettingsURLString)!)
				}
			}

		case .internal(.view(.dismissButtonTapped)):
			switch state.route {
			case .scanQR:
				return .run { send in
					await send(.delegate(.dismiss))
				}
			case let .connectUsingSecrets(connectUsingSecrets):
				guard let connection = connectUsingSecrets.newConnection else {
					return .run { send in
						await send(.delegate(.dismiss))
					}
				}
				return body.reduce(
					into: &state,
					action: .connectUsingSecrets(.delegate(.connected(
						.init(
							client: .init(
								displayName: L10n.NewConnection.defaultNameOfConnection,
								connectionPassword: connectUsingSecrets.connectionSecrets.connectionPassword.data.data
							),
							connection: connection
						)
					)))
				)
			}

		case let .scanQR(.delegate(.connectionSecretsFromScannedQR(connectionSecrets))):
			state.route = .connectUsingSecrets(.init(connectionSecrets: connectionSecrets))
			return .none

		case let .connectUsingSecrets(.delegate(.connected(connection))):
			return .run { send in
				await send(.delegate(.newConnection(connection)))
			}

		case .delegate:
			return .none
		case .scanQR:
			return .none
		case .connectUsingSecrets:
			return .none
		}
	}
}

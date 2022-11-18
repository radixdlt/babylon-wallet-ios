import ComposableArchitecture
import ErrorQueue
import Foundation
import GatewayAPI
import ProfileClient
import URLBuilderClient
import UserDefaultsClient

// MARK: - ManageGatewayAPIEndpoints
public struct ManageGatewayAPIEndpoints: ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.gatewayAPIClient) var gatewayAPIClient
	@Dependency(\.profileClient) var profileClient
	@Dependency(\.urlBuilder) var urlBuilder

	public init() {}
}

public extension ManageGatewayAPIEndpoints {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.didAppear)):
			let currentNetworkAndGateway = profileClient.getNetworkAndGateway()
			state.networkAndGateway = currentNetworkAndGateway
			let url = currentNetworkAndGateway.gatewayAPIEndpointURL
			state.url = url
			if let components = try? urlBuilder.componentsFromURL(url) {
				state.scheme = components.scheme
				state.port = components.port
				state.host = components.host
				state.path = components.path
			}
			return .none

		case .internal(.view(.dismissButtonTapped)):
			return .run { send in
				await send(.delegate(.dismiss))
			}

		case let .internal(.view(.hostChanged(host))):
			state.host = URLInput.Host(host)
			updateURL(into: &state)
			return .none

		case let .internal(.view(.schemeChanged(scheme))):
			state.scheme = URLInput.Scheme(scheme)
			updateURL(into: &state)
			return .none

		case let .internal(.view(.pathChanged(scheme))):
			state.path = URLInput.Path(scheme)
			updateURL(into: &state)
			return .none

		case let .internal(.view(.portChanged(port))):
			state.port = URLInput.Port(port)
			updateURL(into: &state)
			return .none

		case .internal(.view(.switchToButtonTapped)):
			guard let url = state.url else {
				return .none
			}
			state.isValidatingEndpoint = true
			return .run { send in
				await send(.internal(.system(.setGatewayAPIEndpointResult(
					TaskResult {
						try await gatewayAPIClient.setCurrentBaseURL(url)
					}
				))))
			}

		case let .internal(.system(.setGatewayAPIEndpointResult(.success(maybeNew)))):
			state.isValidatingEndpoint = false
			if let new = maybeNew {
				state.networkAndGateway = new
			}
			return .none

		case let .internal(.system(.setGatewayAPIEndpointResult(.failure(error)))):
			state.isValidatingEndpoint = false
			errorQueue.schedule(error)
			return .none

		case .delegate:
			return .none
		}
	}
}

private extension ManageGatewayAPIEndpoints {
	func updateURL(into state: inout State) {
		guard let host = state.host else {
			state.url = nil
			return
		}
		guard let newURL = try? urlBuilder.urlFromInput(
			.init(host: host, scheme: state.scheme, path: state.path, port: state.port)
		) else {
			state.url = nil
			state.isSwitchToButtonEnabled = false
			return
		}

		state.url = newURL
		let currentURL = gatewayAPIClient.getCurrentBaseURL()
		state.isSwitchToButtonEnabled = newURL != currentURL
	}
}

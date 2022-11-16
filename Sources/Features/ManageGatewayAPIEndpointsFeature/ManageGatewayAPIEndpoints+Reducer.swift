import ComposableArchitecture
import Foundation
import GatewayAPI
import ProfileClient
import UserDefaultsClient

// MARK: - ManageGatewayAPIEndpoints
public struct ManageGatewayAPIEndpoints: ReducerProtocol {
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
			state.gatewayAPIURLString = urlBuilder.formatURL(currentNetworkAndGateway.gatewayAPIEndpointURL)
			return .none

		case .internal(.view(.dismissButtonTapped)):
			return .run { send in
				await send(.delegate(.dismiss))
			}

		case let .internal(.view(.gatewayAPIURLChanged(urlString))):
			state.gatewayAPIURLString = urlString
			do {
				let newURL = try urlBuilder.urlFromString(urlString)
				let currentURL = gatewayAPIClient.getCurrentBaseURL()
				state.isSwitchToButtonEnabled = newURL != currentURL
			} catch {
				state.isSwitchToButtonEnabled = false
			}
			return .none

		case .internal(.view(.switchToButtonTapped)):
			precondition(state.isSwitchToButtonEnabled)

			return .run { [urlString = state.gatewayAPIURLString] send in
				await send(.internal(.system(.setGatewayAPIEndpointResult(
					TaskResult {
						try await gatewayAPIClient.setCurrentBaseURL(urlBuilder.urlFromString(urlString))
					}
				))))
			}

		case let .internal(.system(.setGatewayAPIEndpointResult(.success(maybeNew)))):
			if let new = maybeNew {
				state.networkAndGateway = new
			}
			return .none

		case let .internal(.system(.setGatewayAPIEndpointResult(.failure(error)))):
			// FIXME: Error propagation
			print("Failed to set gateway API url: \(String(describing: error))")
			return .none

		case .delegate:
			return .none
		}
	}
}

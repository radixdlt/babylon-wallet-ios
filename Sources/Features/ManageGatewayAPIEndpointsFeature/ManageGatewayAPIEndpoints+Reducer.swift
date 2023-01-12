import CreateAccountFeature
import ErrorQueue
import FeaturePrelude
import Foundation
import GatewayAPI
import ProfileClient
import UserDefaultsClient

// MARK: - ManageGatewayAPIEndpoints
public struct ManageGatewayAPIEndpoints: Sendable, ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.networkSwitchingClient) var networkSwitchingClient
	@Dependency(\.profileClient) var profileClient

	public init() {}
}

public extension ManageGatewayAPIEndpoints {
	var body: some ReducerProtocolOf<Self> {
		Reduce(self.core)
			.ifLet(\.createAccountCoordinator, action: /Action.createAccountCoordinator) {
				CreateAccountCoordinator()
			}
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.didAppear)):
			return .run { send in
				await send(.internal(.system(.loadNetworkAndGatewayResult(
					TaskResult {
						await networkSwitchingClient.getNetworkAndGateway()
					}
				))))
			}

		case let .internal(.system(.loadNetworkAndGatewayResult(.success(currentNetworkAndGateway)))):
			state.currentNetworkAndGateway = currentNetworkAndGateway
			#if DEBUG
			// convenient when testing
			state.urlString = currentNetworkAndGateway.gatewayAPIEndpointURL.absoluteString
			#endif
			return .none

		case let .internal(.system(.loadNetworkAndGatewayResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case .internal(.view(.dismissButtonTapped)):
			return .run { send in
				await send(.delegate(.dismiss))
			}

		case let .internal(.view(.urlStringChanged(urlString))):
			state.urlString = urlString
			let maybeURL = URL(string: urlString)
			state.isSwitchToButtonEnabled = maybeURL != nil && !(state.currentNetworkAndGateway?.gatewayAPIEndpointURL == maybeURL)
			return .none

		case .internal(.view(.switchToButtonTapped)):
			assert(state.isSwitchToButtonEnabled)
			guard let url = URL(string: state.urlString) else {
				return .none
			}
			state.isValidatingEndpoint = true
			return .run { send in
				await send(.internal(.system(.gatewayValidationResult(
					TaskResult {
						try await networkSwitchingClient.validateGatewayURL(url)
					}
				))))
			}

		case let .internal(.view(.focusTextField(focus))):
			state.focusedField = focus
			return .none

		case let .internal(.system(.gatewayValidationResult(.failure(error)))):
			state.isValidatingEndpoint = false
			errorQueue.schedule(error)
			return .none

		case let .internal(.system(.gatewayValidationResult(.success(maybeNew)))):
			state.isValidatingEndpoint = false
			guard let new = maybeNew else {
				return .none
			}
			state.validatedNewNetworkAndGatewayToSwitchTo = new
			return .run { send in
				await send(.internal(.system(.hasAccountsResult(
					TaskResult {
						try await networkSwitchingClient.hasAccountOnNetwork(new)
					}
				))))
			}
		case let .internal(.system(.hasAccountsResult(.success(hasAccountsOnNetwork)))):
			guard let new = state.validatedNewNetworkAndGatewayToSwitchTo else {
				// weird state... should not happen.
				return .none
			}
			return .run { send in
				if hasAccountsOnNetwork {
					await send(.internal(.system(.switchToResult(
						TaskResult {
							try await networkSwitchingClient.switchTo(new)
						}
					))))
				} else {
					await send(.internal(.system(.createAccountOnNetworkBeforeSwitchingToIt(new))))
				}
			}

		case let .internal(.system(.hasAccountsResult(.failure(error)))):
			errorQueue.schedule(error)
			return skipSwitching(state: &state)

		case let .internal(.system(.createAccountOnNetworkBeforeSwitchingToIt(newNetworkAndGateway))):
			state.createAccountCoordinator = .init(
				completionDestination: .home,
				rootState: .init(onNetworkWithID: newNetworkAndGateway.network.id, isFirstAccount: true)
			)
			return .none

		case let .internal(.system(.switchToResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case .internal(.system(.switchToResult(.success))):
			return .run { send in
				await send(.delegate(.networkChanged))
			}

		case .createAccountCoordinator(.delegate(.dismissed)):
			return skipSwitching(state: &state)

		case .createAccountCoordinator(.delegate(.completed)):
			state.createAccountCoordinator = nil
			guard let new = state.validatedNewNetworkAndGatewayToSwitchTo else {
				// weird state... should not happen.
				return .none
			}
			return .run { send in
				await send(.internal(.system(.switchToResult(
					TaskResult {
						try await networkSwitchingClient.switchTo(new)
					}
				))))
			}

		case .createAccountCoordinator, .delegate:
			return .none
		}
	}

	func skipSwitching(state: inout State) -> EffectTask<Action> {
		state.createAccountCoordinator = nil
		state.validatedNewNetworkAndGatewayToSwitchTo = nil
		return .none
	}
}

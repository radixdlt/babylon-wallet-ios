import CreateEntityFeature
import FeaturePrelude
import GatewayAPI
import NetworkSwitchingClient

// MARK: - ManageGatewayAPIEndpoints
public struct ManageGatewayAPIEndpoints: Sendable, ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.networkSwitchingClient) var networkSwitchingClient

	public init() {}
}

extension ManageGatewayAPIEndpoints {
	public var body: some ReducerProtocolOf<Self> {
		Reduce(self.core)
			.presentationDestination(\.$destination, action: /Action.child .. Action.ChildAction.destination) {
				Destinations()
			}
	}

	public func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.didAppear)):
			return .task {
				let result = await TaskResult {
					await networkSwitchingClient.getGateway()
				}
				return .internal(.system(.loadGatewayResult(result)))
			}

		case let .internal(.system(.loadGatewayResult(.success(currentGateway)))):
			state.currentGateway = currentGateway
			#if DEBUG
			// convenient when testing
			state.urlString = currentGateway.url.absoluteString
			#endif
			return .none

		case let .internal(.system(.loadGatewayResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case let .internal(.view(.urlStringChanged(urlString))):
			state.urlString = urlString
			let maybeURL = URL(string: urlString)
			state.isSwitchToButtonEnabled = maybeURL != nil && !(state.currentGateway?.url == maybeURL)
			return .none

		case .internal(.view(.switchToButtonTapped)):
			assert(state.isSwitchToButtonEnabled)
			guard let url = URL(string: state.urlString) else {
				return .none
			}
			state.isValidatingEndpoint = true
			return .task {
				let result = await TaskResult {
					try await networkSwitchingClient.validateGatewayURL(url)
				}
				return .internal(.system(.gatewayValidationResult(result)))
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
			state.validatedNewGatewayToSwitchTo = new
			return .task {
				let result = await TaskResult {
					try await networkSwitchingClient.hasAccountOnNetwork(new)
				}
				return .internal(.system(.hasAccountsResult(result)))
			}
		case let .internal(.system(.hasAccountsResult(.success(hasAccountsOnNetwork)))):
			guard let new = state.validatedNewGatewayToSwitchTo else {
				// weird state... should not happen.
				return .none
			}
			return .task {
				if hasAccountsOnNetwork {
					let result = await TaskResult {
						try await networkSwitchingClient.switchTo(new)
					}
					return .internal(.system(.switchToResult(result)))
				} else {
					return .internal(.system(.createAccountOnNetworkBeforeSwitchingToIt(new)))
				}
			}

		case let .internal(.system(.hasAccountsResult(.failure(error)))):
			errorQueue.schedule(error)
			return skipSwitching(state: &state)

		case let .internal(.system(.createAccountOnNetworkBeforeSwitchingToIt(newGateway))):
			state.destination = .createAccount(
				.init(config: .init(
					specificNetworkID: newGateway.network.id,
					isFirstEntity: false,
					canBeDismissed: true,
					navigationButtonCTA: .goHome
				))
			)
			return .none

		case let .internal(.system(.switchToResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case .internal(.system(.switchToResult(.success))):
			return .send(.delegate(.networkChanged))

		case .child(.destination(.presented(.createAccount(.delegate(.dismissed))))):
			return skipSwitching(state: &state)

		case .child(.destination(.presented(.createAccount(.delegate(.completed))))):
			state.destination = nil
			guard let new = state.validatedNewGatewayToSwitchTo else {
				// weird state... should not happen.
				return .none
			}
			return .task {
				let result = await TaskResult {
					try await networkSwitchingClient.switchTo(new)
				}
				return .internal(.system(.switchToResult(result)))
			}

		case .child, .delegate:
			return .none
		}
	}

	public func skipSwitching(state: inout State) -> EffectTask<Action> {
		state.destination = nil
		state.validatedNewGatewayToSwitchTo = nil
		return .none
	}
}

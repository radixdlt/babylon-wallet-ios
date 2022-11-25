import ComposableArchitecture
import ErrorQueue
import FaucetClient

// MARK: - AccountPreferences
public struct AccountPreferences: ReducerProtocol {
	@Dependency(\.faucetClient) var faucetClient
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.dismissButtonTapped)):
			return .run { send in
				await send(.delegate(.dismissAccountPreferences))
			}
		case .delegate:
			return .none
		case .internal(.view(.didAppear)):
			return loadIsAllowedToUseFaucet(&state)
		case .internal(.view(.faucetButtonTapped)):
			return .run { [address = state.address] send in
				try await faucetClient.getFreeXRD(.init(recipientAccountAddress: address, unlockKeychainPromptShowToUser: "What?"))
				await send(.internal(.system(.disableGetFreeXRDButton)))
				await send(.delegate(.refreshAccount(address)))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}
		case let .internal(.system(.isAllowedToUseFaucet(.success(value)))):
			state.isFaucetButtonEnabled = value
			return .none
		case let .internal(.system(.isAllowedToUseFaucet(.failure(error)))):
			errorQueue.schedule(error)
			return .none
		case .internal(.system(.disableGetFreeXRDButton)):
			state.isFaucetButtonEnabled = false
			return .none
		}
	}
}

private extension AccountPreferences {
	func loadIsAllowedToUseFaucet(_ state: inout State) -> EffectTask<Action> {
		.run { [address = state.address] send in
			await send(.internal(.system(.isAllowedToUseFaucet(
				TaskResult {
					try await faucetClient.isAllowedToUseFaucet(address)
				}
			))))
		}
	}
}

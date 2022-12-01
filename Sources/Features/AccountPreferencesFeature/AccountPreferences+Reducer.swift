import Common
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
				await send(.internal(.system(.presentLoadingState)))
				try await faucetClient.getFreeXRD(.init(recipientAccountAddress: address, unlockKeychainPromptShowToUser: L10n.TransactionSigning.biometricsPrompt))
				await send(.delegate(.refreshAccount(address)))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case let .internal(.system(.isAllowedToUseFaucet(.success(value)))):
			state.isLoading = false
			state.isFaucetButtonEnabled = value
			return .none

		case let .internal(.system(.isAllowedToUseFaucet(.failure(error)))):
			state.isLoading = false
			errorQueue.schedule(error)
			return .none

		case .internal(.system(.presentLoadingState)):
			state.isLoading = true
			return .none

		case .internal(.system(.dismissLoadingState)):
			state.isLoading = false
			return .none

		case .internal(.system(.refreshAccountCompleted)):
			state.isLoading = false
			state.isFaucetButtonEnabled = false
			return .none
		}
	}
}

private extension AccountPreferences {
	func loadIsAllowedToUseFaucet(_ state: inout State) -> EffectTask<Action> {
		.run { [address = state.address] send in
			await send(.internal(.system(.presentLoadingState)))
			await send(.internal(.system(.isAllowedToUseFaucet(
				TaskResult {
					try await faucetClient.isAllowedToUseFaucet(address)
				}
			))))
		}
	}
}

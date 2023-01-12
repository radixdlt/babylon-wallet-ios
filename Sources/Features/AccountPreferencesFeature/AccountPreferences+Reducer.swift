import ErrorQueue
import FaucetClient
import FeaturePrelude

// MARK: - AccountPreferences
public struct AccountPreferences: Sendable, ReducerProtocol {
	@Dependency(\.faucetClient) var faucetClient
	@Dependency(\.errorQueue) var errorQueue

	public init() {}
	private enum RefreshID {}
	public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.dismissButtonTapped)):
			return .run { [address = state.address] send in
				await send(.delegate(.refreshAccount(address)))
				await send(.delegate(.dismissAccountPreferences))
			}

		case .delegate:
			return .cancel(id: RefreshID.self)

		case .internal(.view(.didAppear)):
			return loadIsAllowedToUseFaucet(&state)

		case .internal(.view(.faucetButtonTapped)):
			state.faucetButtonState = .loading(.local)
			return .run { [address = state.address] send in
				do {
					_ = try await faucetClient.getFreeXRD(.init(
						recipientAccountAddress: address,
						unlockKeychainPromptShowToUser: L10n.TransactionSigning.biometricsPrompt
					))
					guard !Task.isCancelled else { return }
					await send(.delegate(.refreshAccount(address)))
				} catch {
					guard !Task.isCancelled else { return }
					await send(.internal(.system(.hideLoader)))
					errorQueue.schedule(error)
				}
			}
			.cancellable(id: RefreshID.self)

		case let .internal(.system(.isAllowedToUseFaucet(.success(value)))):
			state.faucetButtonState = value ? .enabled : .disabled
			return .none

		case let .internal(.system(.isAllowedToUseFaucet(.failure(error)))):
			state.faucetButtonState = .disabled
			errorQueue.schedule(error)
			return .none

		case .internal(.system(.refreshAccountCompleted)):
			state.faucetButtonState = .disabled
			return .none

		case .internal(.system(.hideLoader)):
			state.faucetButtonState = .enabled
			return .none
		}
	}
}

private extension AccountPreferences {
	func loadIsAllowedToUseFaucet(_ state: inout State) -> EffectTask<Action> {
		state.faucetButtonState = .loading(.local)
		return .run { [address = state.address] send in
			await send(.internal(.system(.isAllowedToUseFaucet(
				TaskResult {
					try await faucetClient.isAllowedToUseFaucet(address)
				}
			))))
		}
	}
}

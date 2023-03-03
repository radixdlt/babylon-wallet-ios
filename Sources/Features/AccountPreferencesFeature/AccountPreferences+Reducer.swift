import FaucetClient
import FeaturePrelude

// MARK: - AccountPreferences
public struct AccountPreferences: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let address: AccountAddress
		public var faucetButtonState: ControlState

		public init(
			address: AccountAddress,
			faucetButtonState: ControlState = .enabled
		) {
			self.address = address
			self.faucetButtonState = faucetButtonState
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case closeButtonTapped
		case faucetButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case isAllowedToUseFaucet(TaskResult<Bool>)
		case refreshAccountCompleted
		case hideLoader
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
		case refreshAccount(AccountAddress)
	}

	@Dependency(\.faucetClient) var faucetClient
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return loadIsAllowedToUseFaucet(&state)

		case .closeButtonTapped:
			return .run { [address = state.address] send in
				await send(.delegate(.refreshAccount(address)))
				await send(.delegate(.dismiss))
			}

		case .faucetButtonTapped:
			state.faucetButtonState = .loading(.local)
			return .run { [address = state.address] send in
				do {
					_ = try await faucetClient.getFreeXRD(.init(
						recipientAccountAddress: address
					))
					await send(.delegate(.refreshAccount(address)))
				} catch {
					await send(.internal(.hideLoader))
					if !Task.isCancelled {
						errorQueue.schedule(error)
					}
				}
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .isAllowedToUseFaucet(.success(value)):
			state.faucetButtonState = value ? .enabled : .disabled
			return .none

		case let .isAllowedToUseFaucet(.failure(error)):
			state.faucetButtonState = .disabled
			errorQueue.schedule(error)
			return .none

		case .refreshAccountCompleted:
			state.faucetButtonState = .disabled
			return .none

		case .hideLoader:
			state.faucetButtonState = .enabled
			return .none
		}
	}
}

extension AccountPreferences {
	private func loadIsAllowedToUseFaucet(_ state: inout State) -> EffectTask<Action> {
		state.faucetButtonState = .loading(.local)
		return .run { [address = state.address] send in
			await send(.internal(.isAllowedToUseFaucet(
				TaskResult {
					try await faucetClient.isAllowedToUseFaucet(address)
				}
			)))
		}
	}
}

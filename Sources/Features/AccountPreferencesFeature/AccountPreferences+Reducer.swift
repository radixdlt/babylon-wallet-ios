import AccountPortfoliosClient
import AccountsClient
import FaucetClient
import FeaturePrelude
import ROLAClient

// MARK: - AccountPreferences
public struct AccountPreferences: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let address: AccountAddress
		public var faucetButtonState: ControlState

		#if DEBUG
		public var createAndUploadAuthKeyButtonState: ControlState
		public var createFungibleTokenButtonState: ControlState
		public var createNonFungibleTokenButtonState: ControlState
		public var createMultipleFungibleTokenButtonState: ControlState
		public var createMultipleNonFungibleTokenButtonState: ControlState
		#endif

		public init(
			address: AccountAddress,
			faucetButtonState: ControlState = .enabled
		) {
			self.address = address
			self.faucetButtonState = faucetButtonState

			#if DEBUG
			self.createAndUploadAuthKeyButtonState = .disabled // will load from account from accountsClient and check...
			self.createFungibleTokenButtonState = .enabled
			self.createNonFungibleTokenButtonState = .enabled
			self.createMultipleFungibleTokenButtonState = .enabled
			self.createMultipleNonFungibleTokenButtonState = .enabled
			#endif
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case closeButtonTapped
		case faucetButtonTapped

		#if DEBUG
		case createAndUploadAuthKeyButtonTapped
		case createFungibleTokenButtonTapped
		case createNonFungibleTokenButtonTapped
		case createMultipleFungibleTokenButtonTapped
		case createMultipleNonFungibleTokenButtonTapped
		#endif
	}

	public enum InternalAction: Sendable, Equatable {
		case isAllowedToUseFaucet(TaskResult<Bool>)
		case callDone(updateControlState: WritableKeyPath<State, ControlState>, changeTo: ControlState = .enabled)
		case refreshAccountCompleted(TaskResult<AccountPortfolio>)
		case hideLoader(updateControlState: WritableKeyPath<State, ControlState>)
		case canCreateAuthSigningKey(Bool)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.rolaClient) var rolaClient
	@Dependency(\.faucetClient) var faucetClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return loadIsAllowedToUseFaucet(&state).concatenate(with: loadCanCreateAuthSigningKey(state))

		case .closeButtonTapped:
			return .run { send in
				await send(.delegate(.dismiss))
			}

		case .faucetButtonTapped:
			return call(buttonState: \.faucetButtonState, into: &state) {
				try await faucetClient.getFreeXRD(.init(recipientAccountAddress: $0))
			}
		#if DEBUG
		case .createAndUploadAuthKeyButtonTapped:
			return call(
				buttonState: \.createAndUploadAuthKeyButtonState,
				into: &state,
				onSuccess: .disabled // should not be able to create another authSigning key
			) {
				try await rolaClient.createAuthSigningKeyForAccountIfNeeded(.init(accountAddress: $0))
			}

		case .createFungibleTokenButtonTapped:
			return call(buttonState: \.createFungibleTokenButtonState, into: &state) {
				try await faucetClient.createFungibleToken(.init(
					recipientAccountAddress: $0
				))
			}

		case .createNonFungibleTokenButtonTapped:
			return call(buttonState: \.createNonFungibleTokenButtonState, into: &state) {
				try await faucetClient.createNonFungibleToken(.init(
					recipientAccountAddress: $0
				))
			}
		case .createMultipleFungibleTokenButtonTapped:
			return call(buttonState: \.createMultipleFungibleTokenButtonState, into: &state) {
				try await faucetClient.createFungibleToken(.init(
					recipientAccountAddress: $0,
					numberOfTokens: 50
				))
			}
		case .createMultipleNonFungibleTokenButtonTapped:
			return call(buttonState: \.createMultipleNonFungibleTokenButtonState, into: &state) {
				try await faucetClient.createNonFungibleToken(.init(
					recipientAccountAddress: $0,
					numberOfTokens: 10,
					numberOfIds: 100
				))
			}
		#endif
		}
	}

	private func call(
		buttonState: WritableKeyPath<State, ControlState>,
		into state: inout State,
		onSuccess: ControlState = .enabled,
		call: @escaping @Sendable (AccountAddress) async throws -> Void
	) -> EffectTask<Action> {
		state[keyPath: buttonState] = .loading(.local)
		return .run { [address = state.address] send in
			try await call(address)
			await send(.internal(.callDone(updateControlState: buttonState, changeTo: onSuccess)))
		} catch: { error, send in
			await send(.internal(.hideLoader(updateControlState: buttonState)))
			if !Task.isCancelled {
				errorQueue.schedule(error)
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

		case let .hideLoader(controlStateKeyPath):
			state[keyPath: controlStateKeyPath] = .enabled
			return .none

		case let .callDone(controlStateKeyPath, changeTo):
			if controlStateKeyPath == \State.faucetButtonState {
				return updateAccountPortfolio(state).concatenate(with: loadIsAllowedToUseFaucet(&state))
			} else {
				state[keyPath: controlStateKeyPath] = changeTo
				return .none
			}

		case let .canCreateAuthSigningKey(canCreateAuthSigningKey):
			#if DEBUG
			state.createAndUploadAuthKeyButtonState = canCreateAuthSigningKey ? .enabled : .disabled
			#endif
			return .none
		}
	}
}

extension AccountPreferences {
	private func updateAccountPortfolio(_ state: State) -> EffectTask<Action> {
		.run { [address = state.address] send in
			await send(.internal(.refreshAccountCompleted(
				TaskResult { try await accountPortfoliosClient.fetchAccountPortfolio(address, true) }
			)))
		}
	}

	private func loadIsAllowedToUseFaucet(_ state: inout State) -> EffectTask<Action> {
		state.faucetButtonState = .loading(.local)
		return .run { [address = state.address] send in
			await send(.internal(.isAllowedToUseFaucet(
				TaskResult {
					await faucetClient.isAllowedToUseFaucet(address)
				}
			)))
		}
	}

	private func loadCanCreateAuthSigningKey(_ state: State) -> EffectTask<Action> {
		.run { [address = state.address] send in
			let account = try await accountsClient.getAccountByAddress(address)

			await send(.internal(.canCreateAuthSigningKey(!account.hasAuthenticationSigningKey)))
		}
	}
}

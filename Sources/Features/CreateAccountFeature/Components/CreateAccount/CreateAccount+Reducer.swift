import Cryptography
import FeaturePrelude
import ProfileClient

// MARK: - CreateAccount
public struct CreateAccount: Sendable, ReducerProtocol {
	@Dependency(\.mainQueue) var mainQueue
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.profileClient) var profileClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(self.core)
	}
}

// MARK: Public
public extension CreateAccount {
	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.createAccountButtonTapped)):
			assert(!state.isCreatingAccount)
			state.focusedField = nil
			state.isCreatingAccount = true

			if state.shouldCreateProfile {
				return createProfile(state: &state)
			} else {
				return createAccount(state: &state)
			}

		case let .internal(.system(.createdNewAccountResult(.failure(error)))):
			state.isCreatingAccount = false
			errorQueue.schedule(error)
			return .none

		case let .internal(.system(.createdNewAccountResult(.success(account)))):
			state.isCreatingAccount = false
			return .run { [isFirstAccount = state.isFirstAccount] send in
				await send(.delegate(.createdNewAccount(account: account, isFirstAccount: isFirstAccount)))
			}

		case .internal(.view(.closeButtonTapped)):
			return .run { send in
				await send(.delegate(.dismissCreateAccount))
			}

		case let .internal(.view(.textFieldChanged(accountName))):
			state.inputtedAccountName = accountName
			return .none

		case let .internal(.view(.textFieldFocused(focus))):
			return .run { send in
				try await self.mainQueue.sleep(for: .seconds(0.5))
				await send(.internal(.system(.focusTextField(focus))))
			}

		case .internal(.view(.viewAppeared)):
			return .run { send in
				try await self.mainQueue.sleep(for: .seconds(0.5))
				await send(.internal(.system(.focusTextField(.accountName))))
			}

		case let .internal(.system(.focusTextField(focus))):
			state.focusedField = focus
			return .none

		case .delegate:
			return .none
		}
	}
}

// MARK: Private
private extension CreateAccount {
	static func networkAndGateway(_ configuredNetworkAndGateway: AppPreferences.NetworkAndGateway?, profileClient: ProfileClient) async -> AppPreferences.NetworkAndGateway {
		if let configuredNetworkAndGateway {
			return configuredNetworkAndGateway
		}

		return await profileClient.getNetworkAndGateway()
	}

	func createAccount(state: inout State) -> EffectTask<Action> {
		.run { [accountName = state.sanitizedAccountName, onNetworkWithID = state.onNetworkWithID] send in
			await send(.internal(.system(.createdNewAccountResult(
				TaskResult {
					let request = CreateAccountRequest(
						overridingNetworkID: onNetworkWithID, // optional
						keychainAccessFactorSourcesAuthPrompt: L10n.CreateAccount.biometricsPrompt,
						accountName: accountName
					)
					return try await profileClient.createVirtualAccount(
						request
					)
				}
			))))
		}
	}

	func createProfile(state: inout State) -> EffectTask<Action> {
		.run { [nameOfFirstAccount = state.sanitizedAccountName] send in
			await send(.internal(.system(.createdNewAccountResult(
				TaskResult {
					let accountOnCurrentNetwork = try await profileClient.createNewProfile(
						CreateNewProfileRequest(
							nameOfFirstAccount: nameOfFirstAccount
						)
					)
					return accountOnCurrentNetwork
				}
			))))
		}
	}
}

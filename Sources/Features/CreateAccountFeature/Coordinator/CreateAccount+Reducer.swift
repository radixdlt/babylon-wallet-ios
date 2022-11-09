import ComposableArchitecture
import KeychainClientDependency
import Profile
import ProfileClient

// MARK: - CreateAccount
public struct CreateAccount: ReducerProtocol {
	@Dependency(\.accountNameValidator) var accountNameValidator
	@Dependency(\.mainQueue) var mainQueue
	@Dependency(\.profileClient) var profileClient
	@Dependency(\.keychainClient) var keychainClient

	public init() {}
}

public extension CreateAccount {
	func reduce(into state: inout State, action: Action) -> ComposableArchitecture.Effect<Action, Never> {
		switch action {
		case .internal(.view(.createAccountButtonTapped)):
			precondition(state.isValid)
			precondition(!state.isCreatingAccount)
			state.isCreatingAccount = true
			return .run { [profileClient, accountName = state.accountName] send in
				await send(.internal(.system(.createdNewAccountResult(
					TaskResult {
						let createAccountRequest = CreateAccountRequest(
							accountName: accountName
						)
						return try await profileClient.createAccount(createAccountRequest)
					}
				))))
			}

		case let .internal(.system(.createdNewAccountResult(.success(account)))):
			state.isCreatingAccount = false
			return .run { send in
				await send(.delegate(.createdNewAccount(account)))
			}
		case let .internal(.system(.createdNewAccountResult(.failure(error)))):
			state.isCreatingAccount = false
			return .run { send in
				await send(.delegate(.failedToCreateNewAccount(reason: String(describing: error))))
			}

		case .internal(.view(.closeButtonTapped)):
			return .run { send in
				await send(.delegate(.dismissCreateAccount))
			}

		case let .internal(.view(.textFieldChanged(accountName))):
			let result = accountNameValidator.validate(accountName)
			if !accountNameValidator.isCharacterCountOverLimit(result.trimmedName) {
				state.isValid = result.isValid
				state.accountName = accountName
			}
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

		// FIXME: use reducer func instead - @davdroman-rdx
		case let .internal(.system(.focusTextField(focus))):
			state.focusedField = focus
			return .none

		case .delegate:
			return .none
		}
	}
}

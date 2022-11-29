import ComposableArchitecture
import ErrorQueue
import Profile
import ProfileClient
import LocalAuthenticationClient

// MARK: - CreateAccount
public struct CreateAccount: Sendable, ReducerProtocol {
	@Dependency(\.accountNameValidator) var accountNameValidator
	@Dependency(\.mainQueue) var mainQueue
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.profileClient) var profileClient
    @Dependency(\.localAuthenticationClient) var localAuthenticationClient

	public init() {}
}

public extension CreateAccount {
	func reduce(into state: inout State, action: Action) -> ComposableArchitecture.Effect<Action, Never> {
		switch action {
		case .internal(.view(.createAccountButtonTapped)):
			precondition(state.isValid)
			precondition(!state.isCreatingAccount)
			state.isCreatingAccount = true
			return .run { [accountName = state.accountName] send in
				await send(.internal(.system(.createdNewAccountResult(
					TaskResult {
						let request = CreateAnotherAccountRequest(
							accountName: accountName
						)
						return try await profileClient.createVirtualAccount(
							request
						)
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
			errorQueue.schedule(error)
			return .run { send in
				await send(.delegate(.failedToCreateNewAccount))
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

		case let .internal(.system(.focusTextField(focus))):
			state.focusedField = focus
			return .none

		case .delegate:
			return .none
		}
	}
}

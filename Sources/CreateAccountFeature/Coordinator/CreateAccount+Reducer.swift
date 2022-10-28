import ComposableArchitecture
import KeychainClient
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
		case .internal(.user(.createAccount)):
			precondition(state.isValid)
			return .run { [profileClient, keychainClient, accountName = state.accountName, networkID = state.networkID] send in
				await send(.internal(.system(.createdNewAccountResult(
					TaskResult {
						// FIXME: Think our best approach to generalize this. Maybe we actually SHOULD
						// add the KeychainClient as a "stored propery" of the ProfileClient?
						// Now it is only passed in so that we can use `Profile` Packages convenience
						// method to try to load the correct mnemonic from keychain.
						let createAccountRequest = CreateAccountRequest(
							accountName: accountName,
							keychainClient: keychainClient,
							networkID: networkID
						)
						let newAccount = try await profileClient.createAccount(createAccountRequest)
						let profileSnapshot = try profileClient.extractProfileSnapshot()
						try keychainClient.saveProfileSnapshot(profileSnapshot: profileSnapshot)
						return newAccount
					}
				))))
			}

		case let .internal(.system(.createdNewAccountResult(.success(account)))):
			return .run { send in
				await send(.coordinate(.createdNewAccount(account)))
			}
		case let .internal(.system(.createdNewAccountResult(.failure(error)))):
			return .run { send in
				await send(.coordinate(.failedToCreateNewAccount(reason: String(describing: error))))
			}

		case .internal(.user(.dismiss)):
			return .run { send in
				await send(.coordinate(.dismissCreateAccount))
			}

		case let .internal(.user(.textFieldDidChange(accountName))):
			let result = accountNameValidator.validate(accountName)
			if !accountNameValidator.isCharacterCountOverLimit(result.trimmedName) {
				state.isValid = result.isValid
				state.accountName = accountName
			}
			return .none

		case .internal(.user(.textFieldDidFocus)):
			return .none

		case .internal(.system(.viewDidAppear)):
			return .run { send in
				try await self.mainQueue.sleep(for: .seconds(0.5))
				await send(.internal(.system(.focusTextField)))
			}

		case .internal(.system(.focusTextField)):
			state.focusedField = .accountName
			return .none

		case .coordinate:
			return .none
		}
	}
}

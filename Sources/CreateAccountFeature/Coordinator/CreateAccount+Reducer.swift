import ComposableArchitecture

// MARK: - CreateAccount
public struct CreateAccount: ReducerProtocol {
	@Dependency(\.accountNameValidator) var accountNameValidator
	@Dependency(\.mainQueue) var mainQueue

	public init() {}
}

public extension CreateAccount {
	func reduce(into state: inout State, action: Action) -> ComposableArchitecture.Effect<Action, Never> {
		switch action {
		case .internal(.user(.closeButtonTapped)):
			return .run { send in
				await send(.coordinate(.dismissCreateAccount))
			}
		case .coordinate(.dismissCreateAccount):
			return .none
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
		}
	}
}

import ComposableArchitecture

// MARK: - CreateAccount
public struct CreateAccount: ReducerProtocol {
	public init() {}

	@Dependency(\.accountNameValidator) var accountNameValidator

	public func reduce(into state: inout State, action: Action) -> ComposableArchitecture.Effect<Action, Never> {
		switch action {
		case .internal(.user(.closeButtonTapped)):
			return Effect(value: .coordinate(.dismissCreateAccount))
		case .coordinate(.dismissCreateAccount):
			return .none
		case let .internal(.user(.accountNameChanged(accountName))):
			let result = accountNameValidator.validate(accountName)
			state.isValid = result.isValid
			if !accountNameValidator.isCharacterCountOverLimit(result.trimmedName) {
				state.accountName = accountName
			}
			return .none
		}
	}
}

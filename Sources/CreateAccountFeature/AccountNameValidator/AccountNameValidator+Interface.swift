import ComposableArchitecture

// MARK: - AccountNameValidator
public struct AccountNameValidator {
	public var validate: Validate
	public var isCharacterCountOverLimit: IsCharacterCountOverLimit

	public init(
		validate: @escaping Validate,
		isCharacterCountOverLimit: @escaping IsCharacterCountOverLimit
	) {
		self.validate = validate
		self.isCharacterCountOverLimit = isCharacterCountOverLimit
	}
}

public extension AccountNameValidator {
	typealias Validate = @Sendable (String) -> (isValid: Bool, trimmedName: String)
	typealias IsCharacterCountOverLimit = @Sendable (String) -> Bool
}

public extension DependencyValues {
	var accountNameValidator: AccountNameValidator {
		get { self[AccountNameValidator.self] }
		set { self[AccountNameValidator.self] = newValue }
	}
}

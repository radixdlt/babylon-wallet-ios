import Dependencies
import XCTestDynamicOverlay

public extension DependencyValues {
	var accountNameValidator: AccountNameValidator {
		get { self[AccountNameValidator.self] }
		set { self[AccountNameValidator.self] = newValue }
	}
}

// MARK: - AccountNameValidator + TestDependencyKey
extension AccountNameValidator: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		validate: unimplemented("\(Self.self).validate"),
		isCharacterCountOverLimit: unimplemented("\(Self.self).isCharacterCountOverLimit")
	)
}

extension AccountNameValidator {
	static let noop = Self(
		validate: { _ in (false, "") },
		isCharacterCountOverLimit: { _ in false }
	)
}

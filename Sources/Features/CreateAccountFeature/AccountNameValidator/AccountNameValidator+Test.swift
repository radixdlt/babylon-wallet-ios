#if DEBUG
import Dependencies
import XCTestDynamicOverlay

extension AccountNameValidator: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		validate: unimplemented("\(Self.self).validate"),
		isCharacterCountOverLimit: unimplemented("\(Self.self).isCharacterCountOverLimit")
	)
}

public extension AccountNameValidator {
	static let noop = Self(
		validate: { _ in (false, "") },
		isCharacterCountOverLimit: { _ in false }
	)
}
#endif

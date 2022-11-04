import Foundation

// MARK: - AccountDetails.Environment
public extension AccountDetails {
	// MARK: Environment
	struct Environment {
		public init() {}
	}
}

#if DEBUG
public extension AccountDetails.Environment {
	static let placeholder: Self = .init()

	static let testValue: Self = .init()
}
#endif

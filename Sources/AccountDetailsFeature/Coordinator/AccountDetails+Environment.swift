import Foundation

public extension AccountDetails {
	// MARK: Environment
	struct Environment {
		public init() {}
	}
}

#if DEBUG
public extension AccountDetails.Environment {
	static let placeholder: Self = .init()

	static let unimplemented: Self = .init()
}
#endif

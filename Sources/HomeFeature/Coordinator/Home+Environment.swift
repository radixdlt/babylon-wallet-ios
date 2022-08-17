import ComposableArchitecture
import Foundation

public extension Home {
	// MARK: Environment
	struct Environment {
		public init() {}
	}
}

#if DEBUG
public extension Home.Environment {
	static let placeholder = Self()
}
#endif

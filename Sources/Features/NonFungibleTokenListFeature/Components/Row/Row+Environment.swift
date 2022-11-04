import Foundation

// MARK: - NonFungibleTokenList.Row.Environment
public extension NonFungibleTokenList.Row {
	// MARK: Environment
	struct Environment {
		public init() {}
	}
}

#if DEBUG
public extension NonFungibleTokenList.Row.Environment {
	static let testValue = Self()
}
#endif

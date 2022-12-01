import Foundation

// MARK: - FungibleTokenDetails.State
public extension FungibleTokenDetails {
	struct State: Equatable {
		public init() {}
	}
}

#if DEBUG
public extension FungibleTokenDetails.State {
	static let previewValue: Self = .init()
}
#endif

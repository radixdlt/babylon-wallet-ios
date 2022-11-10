import Common
import ComposableArchitecture

// MARK: FungibleTokenList.State
public extension FungibleTokenList {
	// MARK: State
	struct State: Equatable {
		public var sections: IdentifiedArrayOf<FungibleTokenList.Section.State>

		public init(
			sections: IdentifiedArrayOf<FungibleTokenList.Section.State>
		) {
			self.sections = sections
		}
	}
}

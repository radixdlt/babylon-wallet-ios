import Asset
import Common
import ComposableArchitecture

// MARK: FungibleTokenList.State
public extension FungibleTokenList {
	// MARK: State
	struct State: Sendable, Equatable {
		public var sections: IdentifiedArrayOf<FungibleTokenList.Section.State>
		public var selectedToken: FungibleTokenContainer?

		public init(
			sections: IdentifiedArrayOf<FungibleTokenList.Section.State>,
			selectedToken: FungibleTokenContainer? = nil
		) {
			self.sections = sections
			self.selectedToken = selectedToken
		}
	}
}

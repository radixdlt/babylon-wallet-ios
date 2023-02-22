import FeaturePrelude
import FungibleTokenDetailsFeature

// MARK: FungibleTokenList.State
extension FungibleTokenList {
	// MARK: State
	public struct State: Sendable, Hashable {
		public var sections: IdentifiedArrayOf<FungibleTokenList.Section.State>

		@PresentationState
		public var destination: Destinations.State?

		public init(sections: IdentifiedArrayOf<FungibleTokenList.Section.State>) {
			self.sections = sections
		}
	}
}

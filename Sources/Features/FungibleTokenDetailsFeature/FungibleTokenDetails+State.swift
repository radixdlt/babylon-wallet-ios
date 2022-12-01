import Asset
import Foundation
import Profile

// MARK: - FungibleTokenDetails.State
public extension FungibleTokenDetails {
	struct State: Equatable {
		public var ownedToken: FungibleTokenContainer

		public init(
			ownedToken: FungibleTokenContainer
		) {
			self.ownedToken = ownedToken
		}
	}
}

#if DEBUG
public extension FungibleTokenDetails.State {
	static let previewValue: Self = .init(
		ownedToken: FungibleTokenContainer(
			owner: try! .init(address: "owner_address"),
			asset: .xrd,
			amount: "30.0",
			worth: 500
		)
	)
}
#endif

import FeaturePrelude

// MARK: - FungibleTokenDetails.State
public extension FungibleTokenDetails {
	typealias State = FungibleTokenContainer
}

#if DEBUG
public extension FungibleTokenDetails.State {
	static let previewValue = FungibleTokenContainer(
		owner: try! .init(address: "owner_address"),
		asset: .xrd,
		amount: "30.0",
		worth: 500
	)
}
#endif

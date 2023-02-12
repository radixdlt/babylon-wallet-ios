import FeaturePrelude

// MARK: - FungibleTokenDetails.State
extension FungibleTokenDetails {
	public typealias State = FungibleTokenContainer
}

#if DEBUG
extension FungibleTokenDetails.State {
	public static let previewValue = FungibleTokenContainer(
		owner: try! .init(address: "owner_address"),
		asset: .xrd,
		amount: "30.0",
		worth: 500
	)
}
#endif

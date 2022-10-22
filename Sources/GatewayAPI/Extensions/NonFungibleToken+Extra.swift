import Asset

// MARK: - Convenience
public extension NonFungibleToken {
	init(
		address: ComponentAddress,
		stateComponentResponse _: V0StateComponentResponse
	) {
		self.init(
			address: address,
			// TODO: update when API is ready
			iconURL: nil
		)
	}
}

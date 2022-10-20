import Asset

// MARK: - Convenience
public extension NonFungibleToken {
	init(
		address: ComponentAddress,
		details _: EntityDetailsResponseNonFungibleDetails
	) {
		self.init(
			address: address,
			// TODO: update when API is ready
			iconURL: nil
		)
	}
}

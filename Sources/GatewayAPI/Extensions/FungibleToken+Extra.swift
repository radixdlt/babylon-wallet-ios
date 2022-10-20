import Asset

// MARK: - Convenience
public extension FungibleToken {
	init(
		address: ComponentAddress,
		details: EntityDetailsResponseFungibleDetails
	) throws {
		self.init(
			address: address,
			totalSupplyAttos: try .init(decimalString: details.totalSupplyAttos).inAttos,
			totalMintedAttos: try .init(decimalString: details.totalMintedAttos).inAttos,
			totalBurntAttos: try .init(decimalString: details.totalBurntAttos).inAttos,
			// TODO: update when API is ready
			tokenDescription: nil,
			name: nil,
			code: nil,
			iconURL: nil
		)
	}
}

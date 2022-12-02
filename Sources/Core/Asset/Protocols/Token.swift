import Foundation

// MARK: - Token
public protocol Token: Sendable, Equatable, Identifiable {
	// TODO: possibly update with properties below when API is ready
	// var totalSupplyAttos: String { get }
	// var totalMintedAttos: String { get }
	// var totalBurntAttos: String { get }

	// TODO: possibly delete this old implementation
	/// The known supply of token.
	// 	var supply: Supply { get }
}

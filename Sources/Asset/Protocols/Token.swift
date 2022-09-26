import Foundation

// MARK: - Token
public protocol Token: Sendable, Equatable, Identifiable {
	/// The known supply of token.
	var supply: Supply { get }
}

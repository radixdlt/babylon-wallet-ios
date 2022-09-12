import Foundation

// MARK: - TokenWorthContainer
public struct TokenWorthContainer: Equatable {
	public let token: Token
	public let valueInCurrency: Float?

	public init(
		token: Token,
		valueInCurrency: Float?
	) {
		self.token = token
		self.valueInCurrency = valueInCurrency
	}
}

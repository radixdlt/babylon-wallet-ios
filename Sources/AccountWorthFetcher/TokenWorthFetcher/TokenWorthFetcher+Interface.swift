import Common
import Foundation

// MARK: - TokenWorthFetcher
public struct TokenWorthFetcher {
	public var fetchWorth: @Sendable ([Token], FiatCurrency) async throws -> [TokenWorthContainer]
	public var fetchSingleTokenWorth: @Sendable (Token, FiatCurrency) async throws -> Float?
}

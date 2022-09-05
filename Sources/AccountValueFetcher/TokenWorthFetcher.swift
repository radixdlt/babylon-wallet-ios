import Common
import Foundation

// MARK: - TokenWorthFetcher
public struct TokenWorthFetcher {
	public init() {}
}

// MARK: - Public Methods
public extension TokenWorthFetcher {
	func fetchWorth(for tokens: [Token], in currency: FiatCurrency) -> [TokenWorthContainer] {
		var containers = [TokenWorthContainer]()
		tokens.forEach {
			let worth = fetchSingleTokenWorth($0, in: currency)
			containers.append(.init(token: $0, valueInCurrency: worth))
		}
		return containers
	}
}

// MARK: - Private Methods
private extension TokenWorthFetcher {
	func fetchSingleTokenWorth(_: Token, in _: FiatCurrency) -> Float? {
		// TODO: replace with real implementation when API is ready
		.random(in: 0 ... 10000)
	}
}

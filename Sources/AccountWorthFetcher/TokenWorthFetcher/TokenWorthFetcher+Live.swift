import Common
import Foundation

public extension TokenWorthFetcher {
	static let live: Self = {
		let fetchSingleTokenWorth: @Sendable (Token, FiatCurrency) async throws -> Float? = { _, _ in
			// TODO: replace with real implementation when API is ready
			.random(in: 0 ... 10000)
		}

		return Self(
			fetchWorth: { tokens, currency in
				var containers = [TokenWorthContainer]()
				try await tokens.asyncForEach {
					let worth = try await fetchSingleTokenWorth($0, currency)
					containers.append(.init(token: $0, valueInCurrency: worth))
				}
				return containers
			}, fetchSingleTokenWorth: fetchSingleTokenWorth
		)
	}()
}

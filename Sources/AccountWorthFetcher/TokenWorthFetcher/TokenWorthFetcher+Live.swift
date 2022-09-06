import Foundation

public extension TokenWorthFetcher {
	static let live = Self(
		fetchWorth: { tokens, _ in
			var containers = [TokenWorthContainer]()
			await tokens.asyncForEach { temp in
				//                let worth = try await fetchSingleTokenWorth(temp, currency)
				let worth = Float.random(in: 0 ... 10000)
				containers.append(.init(token: temp, valueInCurrency: worth))
			}
			return containers
		}, fetchSingleTokenWorth: { _, _ in
			// TODO: replace with real implementation when API is ready
			.random(in: 0 ... 10000)
		}
	)
}

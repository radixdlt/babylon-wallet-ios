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
				try await withThrowingTaskGroup(
					of: (token: Token, worth: Float?).self,
					returning: [TokenWorthContainer].self,
					body: { taskGroup in
						var containers = [TokenWorthContainer]()

						for token in tokens {
							taskGroup.addTask {
								let worth = try await fetchSingleTokenWorth(token, currency)
								return (token, worth)
							}
						}

						for try await result in taskGroup {
							containers.append(.init(token: result.token, valueInCurrency: result.worth))
						}

						return containers
					}
				)

			}, fetchSingleTokenWorth: fetchSingleTokenWorth
		)
	}()
}

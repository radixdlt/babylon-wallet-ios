import Foundation

public extension TokenFetcher {
	static let live = Self(
		fetchTokens: { _ in
			// TODO: replace with real implementation when API is ready
			TokenRandomizer.generateRandomTokens()
		}
	)
}

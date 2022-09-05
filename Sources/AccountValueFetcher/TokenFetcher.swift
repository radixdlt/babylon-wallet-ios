import Foundation
import Profile

// MARK: - TokenFetcher
public struct TokenFetcher {
	public init() {}
}

// MARK: - Public Methods
public extension TokenFetcher {
	func fetchTokens(for _: Profile.Account.Address) -> [Token] {
		// TODO: replace with real implementation when API is ready
		TokenRandomizer.generateRandomTokens(10)
	}
}

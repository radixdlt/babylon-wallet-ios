import Foundation
import Profile

// MARK: - TokenFetcher
public struct TokenFetcher {
	public var fetchTokens: @Sendable (Profile.Account.Address) async throws -> [Token]
}

import Profile

public struct Wallet: Equatable {
    public var loadAccounts: @Sendable () async throws -> [Profile.Account]

	// FIXME: wallet
	public static func == (_: Wallet, _: Wallet) -> Bool {
		true
	}
}

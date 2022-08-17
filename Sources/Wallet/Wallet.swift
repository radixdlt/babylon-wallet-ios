import Profile

public struct Wallet: Equatable {
	public var loadAccounts: () -> [Account]

	// FIXME: wallet
	public static func == (_: Wallet, _: Wallet) -> Bool {
		true
	}
}

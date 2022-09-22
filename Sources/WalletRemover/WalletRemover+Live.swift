import UserDefaultsClient

public extension WalletRemover {
	static func live(
		userDefaultsClient: UserDefaultsClient = .live()
	) -> Self {
		Self(
			removeWallet: {
				await userDefaultsClient.removeProfileName()
			}
		)
	}
}

// MARK: - ResetWalletClient
struct ResetWalletClient: Sendable {
	var resetWallet: ResetWallet

	init(
		resetWallet: @escaping ResetWallet
	) {
		self.resetWallet = resetWallet
	}
}

// MARK: ResetWalletClient.ResetWallet
extension ResetWalletClient {
	typealias ResetWallet = @Sendable () async -> Void
}

extension DependencyValues {
	var resetWalletClient: ResetWalletClient {
		get { self[ResetWalletClient.self] }
		set { self[ResetWalletClient.self] = newValue }
	}
}

// MARK: - ResetWalletClient
struct ResetWalletClient {
	var resetWallet: ResetWallet
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

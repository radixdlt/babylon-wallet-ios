// MARK: - ResetWalletClient
public struct ResetWalletClient: Sendable {
	public var resetWallet: ResetWallet

	init(
		resetWallet: @escaping ResetWallet
	) {
		self.resetWallet = resetWallet
	}
}

// MARK: ResetWalletClient.ResetWallet
extension ResetWalletClient {
	public typealias ResetWallet = @Sendable () async -> Void
}

extension DependencyValues {
	public var resetWalletClient: ResetWalletClient {
		get { self[ResetWalletClient.self] }
		set { self[ResetWalletClient.self] = newValue }
	}
}

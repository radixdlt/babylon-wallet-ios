// MARK: - ResetWalletClient
public struct ResetWalletClient: Sendable {
	public var resetWallet: ResetWallet
	public var walletDidReset: WalletDidReset

	init(
		resetWallet: @escaping ResetWallet,
		walletDidReset: @escaping WalletDidReset
	) {
		self.resetWallet = resetWallet
		self.walletDidReset = walletDidReset
	}
}

extension ResetWalletClient {
	public typealias ResetWallet = @Sendable () async -> Void
	public typealias WalletDidReset = @Sendable () -> AnyAsyncSequence<Void>
}

extension DependencyValues {
	public var resetWalletClient: ResetWalletClient {
		get { self[ResetWalletClient.self] }
		set { self[ResetWalletClient.self] = newValue }
	}
}

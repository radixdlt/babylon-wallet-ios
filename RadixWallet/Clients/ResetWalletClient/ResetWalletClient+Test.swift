// MARK: - ResetWalletClient + TestDependencyKey
extension ResetWalletClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		resetWallet: unimplemented("\(Self.self).resetWallet"),
		walletDidReset: unimplemented("\(Self.self).walletDidReset")
	)
}

extension ResetWalletClient {
	public static let noop = Self(
		resetWallet: {},
		walletDidReset: { AsyncLazySequence([]).eraseToAnyAsyncSequence() }
	)
}

// MARK: - ResetWalletClient + TestDependencyKey
extension ResetWalletClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		resetWallet: unimplemented("\(Self.self).resetWallet")
	)
}

extension ResetWalletClient {
	public static let noop = Self(
		resetWallet: {}
	)
}

// MARK: - ResetWalletClient + TestDependencyKey
extension ResetWalletClient: TestDependencyKey {
	static let previewValue = Self.noop

	static let testValue = Self(
		resetWallet: unimplemented("\(Self.self).resetWallet")
	)
}

extension ResetWalletClient {
	static let noop = Self(
		resetWallet: {}
	)
}

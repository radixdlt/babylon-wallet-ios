// MARK: - FaucetClient + TestDependencyKey
extension FaucetClient: TestDependencyKey {
	static let previewValue = Self.noop

	static let testValue: FaucetClient = Self(
		getFreeXRD: unimplemented("\(Self.self).getFreeXRD"),
		isAllowedToUseFaucet: unimplemented("\(Self.self).isAllowedToUseFaucet")
	)
}

extension FaucetClient {
	static let noop = Self(
		getFreeXRD: { _ in },
		isAllowedToUseFaucet: { _ in true }
	)
}

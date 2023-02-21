import ClientPrelude

// MARK: - FaucetClient + TestDependencyKey
extension FaucetClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue: FaucetClient = Self(
		getFreeXRD: unimplemented("\(Self.self).getFreeXRD"),
		isAllowedToUseFaucet: unimplemented("\(Self.self).isAllowedToUseFaucet")
	)
}

extension FaucetClient {
	public static let noop = Self(
		getFreeXRD: { _ in },
		isAllowedToUseFaucet: { _ in true }
	)
}

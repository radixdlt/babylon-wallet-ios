import ClientPrelude

// MARK: - FaucetClient + TestDependencyKey
extension FaucetClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue: FaucetClient = Self(
		getFreeXRD: unimplemented("\(Self.self).getFreeXRD"),
		isAllowedToUseFaucet: unimplemented("\(Self.self).isAllowedToUseFaucet"),
		saveLastUsedEpoch: unimplemented("\(Self.self).saveLasaveLastUsedEpoch")
	)
}

public extension FaucetClient {
	static let noop = Self(
		getFreeXRD: { _ in .init("transactionID-deadbeef") },
		isAllowedToUseFaucet: { _ in true },
		saveLastUsedEpoch: { _ in }
	)
}

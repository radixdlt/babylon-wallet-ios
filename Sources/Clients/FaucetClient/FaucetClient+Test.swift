import ClientPrelude

// MARK: - FaucetClient + TestDependencyKey
extension FaucetClient: TestDependencyKey {
	public static let previewValue = Self.noop
	#if DEBUG
	public static let testValue: FaucetClient = Self(
		getFreeXRD: unimplemented("\(Self.self).getFreeXRD"),
		isAllowedToUseFaucet: unimplemented("\(Self.self).isAllowedToUseFaucet"),
		createFungibleToken: unimplemented("\(Self.self).createFungibleToken"),
		createNonFungibleToken: unimplemented("\(Self.self).createNonFungibleToken")
	)
	#else
	public static let testValue: FaucetClient = Self(
		getFreeXRD: unimplemented("\(Self.self).getFreeXRD"),
		isAllowedToUseFaucet: unimplemented("\(Self.self).isAllowedToUseFaucet")
	)
	#endif
}

extension FaucetClient {
	#if DEBUG
	public static let noop = Self(
		getFreeXRD: { _ in },
		isAllowedToUseFaucet: { _ in true },
		createFungibleToken: { _ in },
		createNonFungibleToken: { _ in }
	)
	#else
	public static let noop = Self(
		getFreeXRD: { _ in },
		isAllowedToUseFaucet: { _ in true }
	)
	#endif
}

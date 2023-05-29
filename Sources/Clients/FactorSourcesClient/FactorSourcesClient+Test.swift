import ClientPrelude

extension DependencyValues {
	public var factorSourcesClient: FactorSourcesClient {
		get { self[FactorSourcesClient.self] }
		set { self[FactorSourcesClient.self] = newValue }
	}
}

// MARK: - FactorSourcesClient + TestDependencyKey
extension FactorSourcesClient: TestDependencyKey {
	public static let previewValue: Self = noop
	public static let testValue = Self(
		getCurrentNetworkID: unimplemented("\(Self.self).getCurrentNetworkID"),
		getFactorSources: unimplemented("\(Self.self).getFactorSources"),
		factorSourcesAsyncSequence: unimplemented("\(Self.self).factorSourcesAsyncSequence"),
		addPrivateHDFactorSource: unimplemented("\(Self.self).addPrivateHDFactorSource"),
		checkIfHasOlympiaFactorSourceForAccounts: unimplemented("\(Self.self).checkIfHasOlympiaFactorSourceForAccounts"),
		saveFactorSource: unimplemented("\(Self.self).saveFactorSource"),
		getSigningFactors: unimplemented("\(Self.self).getSigningFactors"),
		updateLastUsed: unimplemented("\(Self.self).updateLastUsed")
	)

	public static let noop = Self(
		getCurrentNetworkID: { .kisharnet },
		getFactorSources: { throw NoopError() },
		factorSourcesAsyncSequence: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		addPrivateHDFactorSource: { _ in throw NoopError() },
		checkIfHasOlympiaFactorSourceForAccounts: { _ in nil },
		saveFactorSource: { _ in },
		getSigningFactors: { _ in throw NoopError() },
		updateLastUsed: { _ in }
	)
}

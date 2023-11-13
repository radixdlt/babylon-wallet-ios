
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
		getMainDeviceFactorSource: unimplemented("\(Self.self).getMainDeviceFactorSource"),
		getFactorSources: unimplemented("\(Self.self).getFactorSources"),
		factorSourcesAsyncSequence: unimplemented("\(Self.self).factorSourcesAsyncSequence"),
		addPrivateHDFactorSource: unimplemented("\(Self.self).addPrivateHDFactorSource"),
		checkIfHasOlympiaFactorSourceForAccounts: unimplemented("\(Self.self).checkIfHasOlympiaFactorSourceForAccounts"),
		saveFactorSource: unimplemented("\(Self.self).saveFactorSource"),
		updateFactorSource: unimplemented("\(Self.self).updateFactorSource"),
		getSigningFactors: unimplemented("\(Self.self).getSigningFactors"),
		updateLastUsed: unimplemented("\(Self.self).updateLastUsed"),
		flagFactorSourceForDeletion: unimplemented("\(Self.self).flagFactorSourceForDeletion")
	)

	public static let noop = Self(
		getCurrentNetworkID: { .kisharnet },
		getMainDeviceFactorSource: { throw NoopError() },
		getFactorSources: { throw NoopError() },
		factorSourcesAsyncSequence: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		addPrivateHDFactorSource: { _ in throw NoopError() },
		checkIfHasOlympiaFactorSourceForAccounts: { _, _ in nil },
		saveFactorSource: { _ in },
		updateFactorSource: { _ in },
		getSigningFactors: { _ in throw NoopError() },
		updateLastUsed: { _ in },
		flagFactorSourceForDeletion: { _ in }
	)
}

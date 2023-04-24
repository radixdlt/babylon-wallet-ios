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
		getFactorSources: unimplemented("\(Self.self).getFactorSources"),
		factorSourcesAsyncSequence: unimplemented("\(Self.self).factorSourcesAsyncSequence"),
		addPrivateHDFactorSource: unimplemented("\(Self.self).addPrivateHDFactorSource"),
		checkIfHasOlympiaFactorSourceForAccounts: unimplemented("\(Self.self).checkIfHasOlympiaFactorSourceForAccounts"),
		addOffDeviceFactorSource: unimplemented("\(Self.self).addOffDeviceFactorSource"),
		getFactorsOfSigners: unimplemented("\(Self.self).getFactorsOfSigners")
	)

	public static let noop = Self(
		getFactorSources: { throw NoopError() },
		factorSourcesAsyncSequence: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		addPrivateHDFactorSource: { _ in throw NoopError() },
		checkIfHasOlympiaFactorSourceForAccounts: { _ in nil },
		addOffDeviceFactorSource: { _ in },
		getFactorsOfSigners: { _ in throw NoopError() }
	)
}

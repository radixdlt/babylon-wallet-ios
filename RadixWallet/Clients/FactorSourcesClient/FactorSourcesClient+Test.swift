
extension DependencyValues {
	var factorSourcesClient: FactorSourcesClient {
		get { self[FactorSourcesClient.self] }
		set { self[FactorSourcesClient.self] = newValue }
	}
}

// MARK: - FactorSourcesClient + TestDependencyKey
extension FactorSourcesClient: TestDependencyKey {
	static let previewValue = Self.noop

	static let testValue = Self(
		indicesOfEntitiesControlledByFactorSource: unimplemented("\(Self.self).indicesOfEntitiesControlledByFactorSource"),
		getCurrentNetworkID: noop.getCurrentNetworkID,
		getMainDeviceFactorSource: unimplemented("\(Self.self).getMainDeviceFactorSource"),
		createNewMainDeviceFactorSource: unimplemented("\(Self.self).createNewMainDeviceFactorSource"),
		getFactorSources: unimplemented("\(Self.self).getFactorSources"),
		factorSourcesAsyncSequence: noop.factorSourcesAsyncSequence,
		nextEntityIndexForFactorSource: unimplemented("\(Self.self).nextEntityIndexForFactorSource"),
		addPrivateHDFactorSource: unimplemented("\(Self.self).addPrivateHDFactorSource"),
		checkIfHasOlympiaFactorSourceForAccounts: noop.checkIfHasOlympiaFactorSourceForAccounts,
		saveFactorSource: unimplemented("\(Self.self).saveFactorSource"),
		updateFactorSource: unimplemented("\(Self.self).updateFactorSource"),
		getSigningFactors: unimplemented("\(Self.self).getSigningFactors"),
		updateLastUsed: unimplemented("\(Self.self).updateLastUsed"),
		flagFactorSourceForDeletion: unimplemented("\(Self.self).flagFactorSourceForDeletion")
	)

	static let noop = Self(
		indicesOfEntitiesControlledByFactorSource: { _ in throw NoopError() },
		getCurrentNetworkID: { .kisharnet },
		getMainDeviceFactorSource: { throw NoopError() },
		createNewMainDeviceFactorSource: { throw NoopError() },
		getFactorSources: { throw NoopError() },
		factorSourcesAsyncSequence: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		nextEntityIndexForFactorSource: { _ in HdPathComponent(globalKeySpace: 0) },
		addPrivateHDFactorSource: { _ in throw NoopError() },
		checkIfHasOlympiaFactorSourceForAccounts: { _, _ in nil },
		saveFactorSource: { _ in },
		updateFactorSource: { _ in },
		getSigningFactors: { _ in throw NoopError() },
		updateLastUsed: { _ in },
		flagFactorSourceForDeletion: { _ in }
	)
}

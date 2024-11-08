
extension DependencyValues {
	var mnemonicClient: MnemonicClient {
		get { self[MnemonicClient.self] }
		set { self[MnemonicClient.self] = newValue }
	}
}

// MARK: - MnemonicClient + TestDependencyKey
extension MnemonicClient: TestDependencyKey {
	static let testValue = Self(
		generate: unimplemented("\(Self.self).generate"),
		import: unimplemented("\(Self.self).import"),
		lookup: unimplemented("\(Self.self).lookup")
	)

	#if DEBUG
	static let previewValue = Self.noop
	static let noop = Self(
		generate: { _, _ in Mnemonic.sample },
		import: { _, _ in throw NoopError() },
		lookup: { _ in .unknown(.tooShort) }
	)
	#endif // DEBUG
}

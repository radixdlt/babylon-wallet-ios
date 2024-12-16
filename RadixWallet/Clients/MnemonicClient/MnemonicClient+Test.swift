
extension DependencyValues {
	var mnemonicClient: MnemonicClient {
		get { self[MnemonicClient.self] }
		set { self[MnemonicClient.self] = newValue }
	}
}

// MARK: - MnemonicClient + TestDependencyKey
extension MnemonicClient: TestDependencyKey {
    static let previewValue = Self.noop
    
	static let testValue = Self(
		generate: unimplemented("\(Self.self).generate", placeholder: noop.generate),
		import: unimplemented("\(Self.self).import"),
		lookup: unimplemented("\(Self.self).lookup", placeholder: noop.lookup)
	)

	static let noop = Self(
		generate: { _, _ in Mnemonic.sample },
		import: { _, _ in throw NoopError() },
		lookup: { _ in .unknown(.tooShort) }
	)
}

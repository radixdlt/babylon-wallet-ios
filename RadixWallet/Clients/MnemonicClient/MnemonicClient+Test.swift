
extension DependencyValues {
	public var mnemonicClient: MnemonicClient {
		get { self[MnemonicClient.self] }
		set { self[MnemonicClient.self] = newValue }
	}
}

// MARK: - MnemonicClient + TestDependencyKey
extension MnemonicClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		generate: unimplemented("\(Self.self).generate"),
		import: unimplemented("\(Self.self).import"),
		lookup: unimplemented("\(Self.self).lookup")
	)

	public static let noop = Self(
		generate: { _, _ in .sample },
		import: { _, _ in throw NoopError() },
		lookup: { _ in .unknown(.tooShort) }
	)
}

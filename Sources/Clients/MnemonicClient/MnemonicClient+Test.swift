import ClientPrelude
import Cryptography

extension DependencyValues {
	public var mnemonicClient: MnemonicClient {
		get { self[MnemonicClient.self] }
		set { self[MnemonicClient.self] = newValue }
	}
}

// MARK: - MnemonicClient + TestDependencyKey
extension MnemonicClient: TestDependencyKey {
	public static let previewValue: Self = .noop

	public static let noop = Self(
		generate: { _, _ in throw NoopError() },
		import: { _, _ in throw NoopError() }
	)

	public static let testValue = Self(
		generate: unimplemented("\(Self.self).generate"),
		import: unimplemented("\(Self.self).import")
	)
}

import ClientPrelude
import Cryptography

// MARK: - MnemonicClient
public struct MnemonicClient: Sendable, DependencyKey {
	public var generate: Generate
	public init(generate: @escaping Generate) {
		self.generate = generate
	}
}

// MARK: MnemonicClient.Generate
public extension MnemonicClient {
	typealias Generate = @Sendable (BIP39.WordCount, BIP39.Language) throws -> Mnemonic
}

public extension MnemonicClient {
	static let liveValue: Self = .init(generate: { try Mnemonic(wordCount: $0, language: $1) })
}

#if DEBUG
extension MnemonicClient: TestDependencyKey {
	public static let testValue: Self = .init(generate: unimplemented("\(Self.self).generate"))
}
#endif

public extension DependencyValues {
	var mnemonicClient: MnemonicClient {
		get { self[MnemonicClient.self] }
		set { self[MnemonicClient.self] = newValue }
	}
}

import ClientPrelude
import Cryptography

extension MnemonicClient: DependencyKey {
	public typealias Value = MnemonicClient

	public static let liveValue: Self = .init(
		generate: { try Mnemonic(wordCount: $0, language: $1) },
		import: { try Mnemonic(phrase: $0, language: $1) }
	)
}

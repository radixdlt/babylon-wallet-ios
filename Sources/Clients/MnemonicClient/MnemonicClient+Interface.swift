import ClientPrelude
import Cryptography

// MARK: - MnemonicClient
public struct MnemonicClient: Sendable {
	public var generate: Generate
	public var `import`: Import
	public init(
		generate: @escaping Generate,
		import: @escaping Import
	) {
		self.generate = generate
		self.import = `import`
	}
}

extension MnemonicClient {
	public typealias Generate = @Sendable (BIP39.WordCount, BIP39.Language) throws -> Mnemonic
	public typealias Import = @Sendable (String, BIP39.Language?) throws -> Mnemonic
}

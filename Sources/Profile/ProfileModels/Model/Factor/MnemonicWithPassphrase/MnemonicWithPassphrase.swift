import Cryptography
import Prelude

// MARK: - MnemonicWithPassphrase
public struct MnemonicWithPassphrase: Sendable, Hashable, Codable {
	public let mnemonic: Mnemonic
	public let passphrase: String
	public init(mnemonic: Mnemonic, passphrase: String) {
		self.mnemonic = mnemonic
		self.passphrase = passphrase
	}

	public func hdRoot() throws -> HD.Root {
		try mnemonic.hdRoot(passphrase: passphrase)
	}
}

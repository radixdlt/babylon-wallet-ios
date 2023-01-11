import Foundation
import Mnemonic

public struct CreateHierarchicalDeterministicFactorInstanceWithMnemonicInput: CreateHierarchicalDeterministicFactorInstanceInputProtocol {
	public let mnemonic: Mnemonic
	public let bip39Passphrase: String
	public let derivationPath: DerivationPath
	public let includePrivateKey: Bool

	public init(
		mnemonic: Mnemonic,
		bip39Passphrase: String = "",
		derivationPath: DerivationPath,
		includePrivateKey: Bool
	) {
		self.mnemonic = mnemonic
		self.bip39Passphrase = bip39Passphrase
		self.derivationPath = derivationPath
		self.includePrivateKey = includePrivateKey
	}
}

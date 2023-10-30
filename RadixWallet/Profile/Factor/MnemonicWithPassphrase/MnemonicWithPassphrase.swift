import EngineToolkit

// MARK: - MnemonicWithPassphrase
public struct MnemonicWithPassphrase: Sendable, Hashable, Codable {
	public let mnemonic: Mnemonic
	public let passphrase: String
	public init(mnemonic: Mnemonic, passphrase: String = "") {
		self.mnemonic = mnemonic
		self.passphrase = passphrase
	}

	public func hdRoot() throws -> HD.Root {
		try mnemonic.hdRoot(passphrase: passphrase)
	}
}

#if DEBUG
extension MnemonicWithPassphrase {
	public static let testValue: Self = .testValueZooVote
	public static let testValueZooVote: Self = .init(mnemonic: .testValueZooVote)
	public static let testValueAbandonArt: Self = .init(mnemonic: .testValueAbandonArt)
}
#endif

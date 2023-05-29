import Cryptography
import Prelude

// MARK: - BIP39.WordCount + Codable
extension BIP39.WordCount: Codable {}

// MARK: - BIP39.Language + Codable
extension BIP39.Language: Codable {}

// MARK: - FactorSource.Storage.OffDeviceMnemonic
extension FactorSource.Storage {
	public struct OffDeviceMnemonic: Sendable, Codable, Hashable {
		public let wordCount: BIP39.WordCount
		public let language: BIP39.Language
		public let usedBip39Passphrase: Bool
	}
}

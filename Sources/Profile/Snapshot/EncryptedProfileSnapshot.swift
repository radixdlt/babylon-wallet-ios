import Cryptography
import Prelude

// MARK: - EncryptedProfileSnapshot
/// An encryption of a `ProfileSnapshot` with crypto metadata about how it was encrypted, which can
/// be used to decrypt it, given a user provided password.
public struct EncryptedProfileSnapshot: Sendable, Codable, Hashable {
	/// Encrypted JSON encoding of a `ProfileSnapshot`
	public let encryptedSnapshot: HexCodable

	/// The KDF algorithm which was used to derive the encryption key from the user provided password.
	public let keyDerivationScheme: PasswordBasedKeyDerivationScheme

	/// The encryption algorithm which was used to produce `encryptedSnapshot` with the encryption key
	/// derived using the `keyDerivationScheme`.
	public let encryptionScheme: EncryptionScheme

	public init(
		encryptedSnapshot: HexCodable,
		keyDerivationScheme: PasswordBasedKeyDerivationScheme,
		encryptionScheme: EncryptionScheme
	) {
		self.encryptedSnapshot = encryptedSnapshot
		self.keyDerivationScheme = keyDerivationScheme
		self.encryptionScheme = encryptionScheme
	}
}

extension EncryptedProfileSnapshot {
	public func decrypt(password: String) throws -> ProfileSnapshot {
		@Dependency(\.jsonDecoder) var jsonDecoder
		let decryptionKey = keyDerivationScheme.kdf(password: password)
		let decrypted = try encryptionScheme.decrypt(data: encryptedSnapshot.data, decryptionKey: decryptionKey)
		let decoded = try jsonDecoder().decode(ProfileSnapshot.self, from: decrypted)
		return decoded
	}
}

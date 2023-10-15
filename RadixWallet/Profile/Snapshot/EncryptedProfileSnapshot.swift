import EngineToolkitimport EngineToolkit

// MARK: - EncryptedProfileSnapshot
/// An encryption of a `ProfileSnapshot` with crypto metadata about how it was encrypted, which can
/// be used to decrypt it, given a user provided password.
public struct EncryptedProfileSnapshot: Sendable, Codable, Hashable {
	public typealias Version = Tagged<Self, UInt32>

	/// JSON format version of this struct
	public let version: Version

	/// Encrypted JSON encoding of a `ProfileSnapshot`
	public let encryptedSnapshot: HexCodable

	/// The KDF algorithm which was used to derive the encryption key from the user provided password.
	public let keyDerivationScheme: PasswordBasedKeyDerivationScheme

	/// The encryption algorithm which was used to produce `encryptedSnapshot` with the encryption key
	/// derived using the `keyDerivationScheme`.
	public let encryptionScheme: EncryptionScheme

	public init(
		version: Version,
		encryptedSnapshot: HexCodable,
		keyDerivationScheme: PasswordBasedKeyDerivationScheme,
		encryptionScheme: EncryptionScheme
	) {
		self.version = version
		self.encryptedSnapshot = encryptedSnapshot
		self.keyDerivationScheme = keyDerivationScheme
		self.encryptionScheme = encryptionScheme
	}
}

extension EncryptedProfileSnapshot.Version {
	public static let current: Self = 1
}

extension EncryptedProfileSnapshot {
	public func decrypt(password: String) throws -> ProfileSnapshot {
		@Dependency(\.jsonDecoder) var jsonDecoder
		let decryptionKey = keyDerivationScheme.kdf(password: password)
		let decrypted = try encryptionScheme.decrypt(data: encryptedSnapshot.data, decryptionKey: decryptionKey)
		let decoded = try jsonDecoder().decode(ProfileSnapshot.self, from: decrypted)
		return decoded
	}

	public static func encrypting(
		_ snapshot: ProfileSnapshot,
		password: String,
		kdfScheme: PasswordBasedKeyDerivationScheme,
		encryptionScheme: EncryptionScheme
	) throws -> Self {
		try snapshot.encrypt(password: password, kdfScheme: kdfScheme, encryptionScheme: encryptionScheme)
	}
}

extension ProfileSnapshot {
	public func encrypt(
		password: String,
		kdfScheme: PasswordBasedKeyDerivationScheme,
		encryptionScheme: EncryptionScheme
	) throws -> EncryptedProfileSnapshot {
		@Dependency(\.jsonEncoder) var jsonEncoder

		let encryptionKey = kdfScheme.kdf(password: password)

		let json = try jsonEncoder().encode(self)

		let encryptedPayload = try encryptionScheme.encrypt(
			data: json,
			encryptionKey: encryptionKey
		)

		return .init(
			version: .current,
			encryptedSnapshot: .init(data: encryptedPayload),
			keyDerivationScheme: kdfScheme,
			encryptionScheme: encryptionScheme
		)
	}
}

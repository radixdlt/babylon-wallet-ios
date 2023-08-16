import CryptoKit
import Prelude

// MARK: - VersionedAlgorithm
public protocol VersionedAlgorithm {
	associatedtype Version: Comparable
	static var version: Version { get }
	static var description: String { get }
}

// MARK: - KeyDeriving
public protocol KeyDeriving {
	func kdf(password: String) -> SymmetricKey
}

extension Comparable where Self: RawRepresentable, RawValue: Comparable {
	public static func < (rhs: Self, lhs: Self) -> Bool {
		rhs.rawValue < lhs.rawValue
	}
}

// MARK: - KeyDerivationScheme
/// The KDF algorithm used to derive the decryption key from a user provided password.
public enum KeyDerivationScheme: Sendable, Hashable, Codable, KeyDeriving {
	case version1(Version1)
	public static let `default`: Self = .version1(.init())

	public func kdf(password: String) -> SymmetricKey {
		switch self {
		case let .version1(scheme): return scheme.kdf(password: password)
		}
	}
}

// MARK: - KDFVersion
public enum KDFVersion: Int, Sendable, Hashable, Codable, Comparable {
	case version1 = 1
}

// MARK: - KeyDerivationScheme.Version1
extension KeyDerivationScheme {
	/// A simple `HKDF` based scheme using UTF8 encoding of the password as input.
	public struct Version1: Sendable, Hashable, Codable, KeyDeriving, VersionedAlgorithm {
		public static let version = KDFVersion.version1
		public static let description = "HKDFSHA256-with-UTF8-encoding-of-password-no-salt-no-info"
		public init() {}

		public func kdf(password: String) -> SymmetricKey {
			let inputKeyMaterial = SymmetricKey(data: Data(password.utf8))
			return HKDF<SHA256>.deriveKey(
				inputKeyMaterial: inputKeyMaterial,
				outputByteCount: SHA256.byteCount
			)
		}
	}
}

// MARK: - Encrypting
public protocol Encrypting: Codable {
	func encrypt(data: Data, encryptionKey key: SymmetricKey) throws -> Data
	func decrypt(data: Data, decryptionKey key: SymmetricKey) throws -> Data
}

extension Encrypting {
	public func encrypt(data: HexCodable, encryptionKey key: SymmetricKey) throws -> Data {
		try encrypt(data: data.data, encryptionKey: key)
	}

	public func decrypt(data: HexCodable, decryptionKey key: SymmetricKey) throws -> Data {
		try decrypt(data: data.data, decryptionKey: key)
	}
}

// MARK: - EncryptionScheme
public enum EncryptionScheme: Sendable, Hashable, Codable, Encrypting {
	case aes(EncryptionAES256GCM)
	public static let `default`: Self = .aes(.init())
}

extension EncryptionScheme {
	public func encrypt(data: Data, encryptionKey key: SymmetricKey) throws -> Data {
		switch self {
		case let .aes(aes):
			return try aes.encrypt(data: data, encryptionKey: key)
		}
	}

	public func decrypt(data: Data, decryptionKey key: SymmetricKey) throws -> Data {
		switch self {
		case let .aes(aes):
			return try aes.decrypt(data: data, decryptionKey: key)
		}
	}
}

// MARK: - EncryptionAES256GCM
public struct EncryptionAES256GCM: Sendable, Hashable, Codable, Encrypting {
	public static let algorithm: String = "AESGCM256"
	private let algorithm: String
	public let version: EncryptionAES256GCMVersion
	public init(version: EncryptionAES256GCMVersion = .default) {
		self.algorithm = Self.algorithm
		self.version = version
	}
}

extension EncryptionAES256GCM {
	public func encrypt(data: Data, encryptionKey key: SymmetricKey) throws -> Data {
		try version.encrypt(data: data, encryptionKey: key)
	}

	public func decrypt(data: Data, decryptionKey key: SymmetricKey) throws -> Data {
		try version.decrypt(data: data, decryptionKey: key)
	}
}

// MARK: - EncryptionAES256GCMVersion
public enum EncryptionAES256GCMVersion: String, Sendable, Hashable, Codable, Encrypting {
	case version1
	public static let `default`: Self = .version1
}

extension EncryptionAES256GCMVersion {
	public func encrypt(data: Data, encryptionKey key: SymmetricKey) throws -> Data {
		switch self {
		case .version1:
			return try EncryptionAES256GCM_Version1().encrypt(data: data, encryptionKey: key)
		}
	}

	public func decrypt(data: Data, decryptionKey key: SymmetricKey) throws -> Data {
		switch self {
		case .version1:
			return try EncryptionAES256GCM_Version1().decrypt(data: data, decryptionKey: key)
		}
	}
}

// MARK: - EncryptionAES256GCM_Version1
public struct EncryptionAES256GCM_Version1: Encrypting {
	public init() {}

	public func encrypt(data: Data, encryptionKey key: SymmetricKey) throws -> Data {
		let sealedBox = try AES.GCM.seal(data, using: key)
		guard let combined = sealedBox.combined else {
			struct SealedBoxContainsNoCombinedCipher: Swift.Error {}
			throw SealedBoxContainsNoCombinedCipher()
		}
		return combined
	}

	public func decrypt(data: Data, decryptionKey key: SymmetricKey) throws -> Data {
		let sealedBox = try AES.GCM.SealedBox(combined: data)
		return try AES.GCM.open(sealedBox, using: key)
	}
}

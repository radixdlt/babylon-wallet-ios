import CryptoKit
import Prelude

// MARK: - VersionedKeyDerivation
public protocol VersionedKeyDerivation {
	associatedtype Version
	static var version: Version { get }
	static var description: String { get }
}

// MARK: - VersionedPasswordBasedKeyDerivation
public protocol VersionedPasswordBasedKeyDerivation: VersionedKeyDerivation where Version == PasswordBasedKeyDerivationScheme.Version {
	static func kdf(password: String) -> SymmetricKey
}

// MARK: - PasswordBasedKeyDerivationScheme
/// The KDF algorithm used to derive the decryption key from a user provided password.
public enum PasswordBasedKeyDerivationScheme: Sendable, Hashable, VersionedAlgorithm {
	case version1
}

extension PasswordBasedKeyDerivationScheme {
	public init(version: Version) {
		switch version {
		case .version1: self = .version1
		}
	}

	public static let `default`: Self = .version1

	private var schemeVersion: any VersionedPasswordBasedKeyDerivation.Type {
		switch self {
		case .version1: return Version1.self
		}
	}

	public var version: Version {
		schemeVersion.version
	}

	public var description: String {
		schemeVersion.description
	}

	public func kdf(password: String) -> SymmetricKey {
		schemeVersion.kdf(password: password)
	}
}

// MARK: PasswordBasedKeyDerivationScheme.Version
extension PasswordBasedKeyDerivationScheme {
	public enum Version: Int, Sendable, Hashable, Codable {
		case version1 = 1
	}
}

// MARK: PasswordBasedKeyDerivationScheme.Version1
extension PasswordBasedKeyDerivationScheme {
	/// A simple `HKDF` based scheme using UTF8 encoding of the password as input.
	public struct Version1: VersionedPasswordBasedKeyDerivation {
		public static let version = Version.version1
		public static let description = "HKDFSHA256-with-UTF8-encoding-of-password-no-salt-no-info"

		public static func kdf(password: String) -> SymmetricKey {
			let inputKeyMaterial = SymmetricKey(data: Data(password.utf8))
			return HKDF<SHA256>.deriveKey(
				inputKeyMaterial: inputKeyMaterial,
				outputByteCount: SHA256.byteCount
			)
		}
	}
}

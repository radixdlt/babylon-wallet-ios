import CryptoKit
import Prelude

// MARK: - KeyDeriving
public protocol KeyDeriving {
	var description: String { get }
	var version: KDFVersion { get }
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
	case version1(Version1 = .default)

	private enum CodingKeys: String, CodingKey {
		case version, description
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let discriminator = try container.decode(KDFVersion.self, forKey: .version)

		switch discriminator {
		case .version1:
			self = .version1(.default)
		}
	}

	public var version: KDFVersion {
		switch self {
		case let .version1(scheme): return scheme.version
		}
	}

	public var description: String {
		switch self {
		case let .version1(scheme): return scheme.description
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(version, forKey: .version)
		try container.encode(description, forKey: .description)
	}

	public static let `default`: Self = .version1(.default)

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
	public struct Version1: Sendable, Hashable, Codable, KeyDeriving {
		public let version: KDFVersion
		public let description: String

		public static let version = KDFVersion.version1
		public static let description = "HKDFSHA256-with-UTF8-encoding-of-password-no-salt-no-info"

		fileprivate init() {
			self.version = Self.version
			self.description = Self.description
		}

		public static let `default`: Self = .init()

		public func kdf(password: String) -> SymmetricKey {
			let inputKeyMaterial = SymmetricKey(data: Data(password.utf8))
			return HKDF<SHA256>.deriveKey(
				inputKeyMaterial: inputKeyMaterial,
				//                salt: // FIXME: Use description as salt?
				//                info: // FIXME: Use version as info?
				outputByteCount: SHA256.byteCount
			)
		}
	}
}

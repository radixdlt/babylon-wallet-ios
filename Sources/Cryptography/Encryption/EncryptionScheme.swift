import CryptoKit
import Prelude

// MARK: - VersionedEncryption
public protocol VersionedEncryption {
	static var version: EncryptionScheme.Version { get }
	static var description: String { get }

	static func encrypt(data: Data, encryptionKey key: SymmetricKey) throws -> Data
	static func decrypt(data: Data, decryptionKey key: SymmetricKey) throws -> Data
}

// MARK: - EncryptionScheme
public enum EncryptionScheme: Sendable, Hashable, VersionedAlgorithm {
	case version1
}

extension EncryptionScheme {
	public init(version: Version) {
		switch version {
		case .version1: self = .version1
		}
	}

	public static let `default`: Self = .version1

	private var schemeVersion: any VersionedEncryption.Type {
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

	public func encrypt(data: Data, encryptionKey key: SymmetricKey) throws -> Data {
		try schemeVersion.encrypt(data: data, encryptionKey: key)
	}

	public func decrypt(data: Data, decryptionKey key: SymmetricKey) throws -> Data {
		try schemeVersion.decrypt(data: data, decryptionKey: key)
	}
}

// MARK: EncryptionScheme.Version
extension EncryptionScheme {
	public enum Version: Int, Sendable, Hashable, Codable {
		case version1 = 1
	}
}

// MARK: EncryptionScheme.Version1
extension EncryptionScheme {
	/// AES GCM 256 encryption
	public struct Version1: VersionedEncryption {
		public static let version: Version = .version1
		public static let description = "AESGCM-256"

		public static func encrypt(data: Data, encryptionKey key: SymmetricKey) throws -> Data {
			let sealedBox = try AES.GCM.seal(data, using: key)
			guard let combined = sealedBox.combined else {
				struct SealedBoxContainsNoCombinedCipher: Swift.Error {}
				throw SealedBoxContainsNoCombinedCipher()
			}
			return combined
		}

		public static func decrypt(data: Data, decryptionKey key: SymmetricKey) throws -> Data {
			let sealedBox = try AES.GCM.SealedBox(combined: data)
			return try AES.GCM.open(sealedBox, using: key)
		}
	}
}

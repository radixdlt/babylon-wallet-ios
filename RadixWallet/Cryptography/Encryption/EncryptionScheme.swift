import CryptoKit

// MARK: - VersionedEncryption
protocol VersionedEncryption {
	static var version: EncryptionScheme.Version { get }
	static var description: String { get }

	static func encrypt(data: Data, encryptionKey key: SymmetricKey) throws -> Data
	static func decrypt(data: Data, decryptionKey key: SymmetricKey) throws -> Data
}

// MARK: - EncryptionScheme
enum EncryptionScheme: Sendable, Hashable, VersionedAlgorithm {
	case version1
}

extension EncryptionScheme {
	init(version: Version) {
		switch version {
		case .version1: self = .version1
		}
	}

	static let `default`: Self = .version1

	private var schemeVersion: any VersionedEncryption.Type {
		switch self {
		case .version1: Version1.self
		}
	}

	var version: Version {
		schemeVersion.version
	}

	var description: String {
		schemeVersion.description
	}

	func encrypt(data: Data, encryptionKey key: SymmetricKey) throws -> Data {
		try schemeVersion.encrypt(data: data, encryptionKey: key)
	}

	func decrypt(data: Data, decryptionKey key: SymmetricKey) throws -> Data {
		try schemeVersion.decrypt(data: data, decryptionKey: key)
	}
}

// MARK: EncryptionScheme.Version
extension EncryptionScheme {
	enum Version: Int, Sendable, Hashable, Codable {
		case version1 = 1
	}
}

// MARK: EncryptionScheme.Version1
extension EncryptionScheme {
	/// AES GCM 256 encryption
	struct Version1: VersionedEncryption {
		static let version: Version = .version1
		static let description = "AESGCM-256"

		static func encrypt(data: Data, encryptionKey key: SymmetricKey) throws -> Data {
			let sealedBox = try AES.GCM.seal(data, using: key)
			guard let combined = sealedBox.combined else {
				struct SealedBoxContainsNoCombinedCipher: Swift.Error {}
				throw SealedBoxContainsNoCombinedCipher()
			}
			return combined
		}

		static func decrypt(data: Data, decryptionKey key: SymmetricKey) throws -> Data {
			let sealedBox = try AES.GCM.SealedBox(combined: data)
			return try AES.GCM.open(sealedBox, using: key)
		}
	}
}

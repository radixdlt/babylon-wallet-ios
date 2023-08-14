import CryptoKit
import Prelude

// MARK: - Encrypting
public protocol Encrypting {
	func encrypt(data: Data, key: SymmetricKey) throws -> Data
	func decrypt(data: Data, key: SymmetricKey) throws -> Data
}

// MARK: - EncryptionAES256GCM
public enum EncryptionAES256GCM: String, Sendable, Hashable, Codable, Encrypting {
	case version1
	public static let `default`: Self = .version1
}

extension EncryptionAES256GCM {
	public func encrypt(data: Data, key: SymmetricKey) throws -> Data {
		switch self {
		case .version1:
			return try EncryptionAES256GCM_Version1().encrypt(data: data, key: key)
		}
	}

	public func decrypt(data: Data, key: SymmetricKey) throws -> Data {
		switch self {
		case .version1:
			return try EncryptionAES256GCM_Version1().decrypt(data: data, key: key)
		}
	}
}

// MARK: - EncryptionAES256GCM_Version1
public struct EncryptionAES256GCM_Version1: Encrypting {
	public init() {}
	public func decrypt(data: Data, key: SymmetricKey) throws -> Data {
		let sealedBox = try AES.GCM.SealedBox(combined: data)
		return try AES.GCM.open(sealedBox, using: key)
	}

	public func encrypt(data: Data, key: SymmetricKey) throws -> Data {
		let sealedBox = try AES.GCM.seal(data, using: key)
		guard let combined = sealedBox.combined else {
			struct SealedBoxContainsNoCombinedCipher: Swift.Error {}
			throw SealedBoxContainsNoCombinedCipher()
		}
		return combined
	}
}

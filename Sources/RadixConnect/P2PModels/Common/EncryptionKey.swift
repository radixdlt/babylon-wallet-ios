import Cryptography
import Prelude

// MARK: - EncryptionKey
// `Data` is `Sendable`, but `CryptoKit.SymmetricKey` (`EncryptionKey`) is not.
public struct EncryptionKey: Sendable, Hashable {
	public let data: Data
	public init(data: Data) throws {
		guard data.count == Self.byteCount else {
			loggerGlobal.error("EncryptionKey:data bad length: \(data.count)")
			throw Error.incorrectByteCount(got: data.count, butExpected: Self.byteCount)
		}
		self.data = data
	}
}

public extension EncryptionKey {
	enum Error: Swift.Error {
		case incorrectByteCount(got: Int, butExpected: Int)
	}

	static let byteCount = 32
	var symmetric: SymmetricKey {
		.init(data: data)
	}
}

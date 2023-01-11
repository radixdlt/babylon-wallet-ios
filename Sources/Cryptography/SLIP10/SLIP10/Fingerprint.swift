import CryptoKit
import Foundation

// MARK: - Fingerprint
public struct Fingerprint: Hashable {
	public let fingerprint: Data
	public init(data: Data) throws {
		guard data.count == Self.byteCount else {
			throw Error.incorrectByteCount(expected: Self.byteCount, butGot: data.count)
		}
		self.fingerprint = data
	}
}

public extension Fingerprint {
	static let byteCount = 4
	enum Error: Swift.Error {
		case incorrectByteCount(expected: Int, butGot: Int)
	}

	static let masterKey = try! Self(data: Data([0x00, 0x00, 0x00, 0x00]))
}

extension Fingerprint {
	init<PublicKey>(publicKey: PublicKey) where PublicKey: ECPublicKey {
		var publicKeyBytes = publicKey.compressedRepresentation

		if publicKeyBytes.count == 32 {
			publicKeyBytes = Data([0x00] + publicKeyBytes)
		}
		assert(publicKeyBytes.count == 33)
		let sha256Hash = Data(SHA256.hash(data: publicKeyBytes))
		var ripe160 = RIPEMD160()
		ripe160.update(data: sha256Hash)
		let keyId = ripe160.finalize()
		let fingerprintData = Data(keyId.prefix(Self.byteCount))

		try! self.init(data: fingerprintData)
	}
}

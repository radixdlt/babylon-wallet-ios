import CryptoKit
import Foundation
import Prelude

public extension SignalingClient.EncryptionKey {
	private var symmetric: SymmetricKey {
		.init(data: self.data.data)
	}

	func decrypt(data: Data) throws -> Data {
		try AES.GCM.open(
			AES.GCM.SealedBox(combined: data),
			using: symmetric
		)
	}

	func encrypt(data: Data) throws -> Data {
		try AES.GCM
			.seal(data, using: symmetric)
			.combined!
	}
}

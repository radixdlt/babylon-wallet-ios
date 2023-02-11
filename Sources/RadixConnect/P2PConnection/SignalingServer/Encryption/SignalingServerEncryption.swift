import CryptoKit
import Foundation
import P2PModels

// MARK: - SignalingServerEncryption
public struct SignalingServerEncryption: Sendable {
	private let key: EncryptionKey
	public init(key: EncryptionKey) {
		self.key = key
	}
}

extension SignalingServerEncryption {
	public func encrypt(_ message: RPCMessageUnencrypted) throws -> RPCMessage {
		let encrypted = try AES.GCM
			.seal(
				message.unencryptedPayload,
				using: key.symmetric
			)
			.combined!

		return RPCMessage(
			encryption: encrypted,
			of: message
		)
	}

	public func decrypt(data msg: Data) throws -> Data {
		try AES.GCM.open(
			AES.GCM.SealedBox(combined: msg),
			using: key.symmetric
		)
	}
}

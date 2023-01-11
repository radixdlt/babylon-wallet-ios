import Foundation
import P2PModels

// MARK: - RTCPrimitiveToMessagePacker
public final class RTCPrimitiveToMessagePacker: Sendable {
	private let jsonEncoder: JSONEncoder
	private let signalingServerEncryption: SignalingServerEncryption
	private let connectionID: P2PConnectionID
	public init(
		connectionID: P2PConnectionID,
		signalingServerEncryption: SignalingServerEncryption,
		jsonEncoder: JSONEncoder = .init()
	) {
		self.connectionID = connectionID
		self.signalingServerEncryption = signalingServerEncryption
		self.jsonEncoder = jsonEncoder
	}
}

public extension RTCPrimitiveToMessagePacker {
	convenience init(
		connectionSecrets: ConnectionSecrets,
		jsonEncoder: JSONEncoder = .init()
	) {
		self.init(
			connectionID: connectionSecrets.connectionID,
			signalingServerEncryption: .init(key: connectionSecrets.encryptionKey),
			jsonEncoder: jsonEncoder
		)
	}
}

public extension RTCPrimitiveToMessagePacker {
	func pack(primitive: WebRTCPrimitive) throws -> SignalingServerMessage.Outgoing {
		let unencryptedPayload = try jsonEncoder.encode(primitive)

		let unencryptedMessage = RPCMessageUnencrypted(
			method: primitive.method,
			source: .mobileWallet,
			connectionId: connectionID,
			requestId: .init(),
			unencryptedPayload: unencryptedPayload
		)

		return try signalingServerEncryption.encrypt(unencryptedMessage)
	}
}

internal extension WebRTCPrimitive {
	var method: RPCMethod {
		switch self {
		case .answer: return .answer
		case .iceCandidate: return .iceCandidate
		case .offer: return .offer
		}
	}
}

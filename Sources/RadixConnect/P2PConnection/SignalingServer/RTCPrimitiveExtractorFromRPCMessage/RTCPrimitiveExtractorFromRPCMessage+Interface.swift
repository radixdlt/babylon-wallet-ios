import Foundation
import P2PModels

// MARK: - RTCPrimitiveExtractorFromRPCMessage
public final class RTCPrimitiveExtractorFromRPCMessage: Sendable {
	private let signalingServerEncryption: SignalingServerEncryption
	private let connectionID: P2PConnectionID

	public init(
		connectionID: P2PConnectionID,
		signalingServerEncryption: SignalingServerEncryption
	) {
		self.connectionID = connectionID
		self.signalingServerEncryption = signalingServerEncryption
	}
}

public extension RTCPrimitiveExtractorFromRPCMessage {
	convenience init(
		connectionSecrets: ConnectionSecrets
	) {
		self.init(
			connectionID: connectionSecrets.connectionID,
			signalingServerEncryption: .init(key: connectionSecrets.encryptionKey)
		)
	}
}

public extension RTCPrimitiveExtractorFromRPCMessage {
	func extract(rpcMessage: RPCMessage) throws -> WebRTCPrimitive {
		guard rpcMessage.connectionID == self.connectionID else {
			throw ConverseError.signalingServer(
				.wrongConnectionSecretForEncryptedRPCMessage(
					rpcHasConnectionID: rpcMessage.connectionID,
					connectionIDFromSecrets: self.connectionID
				)
			)
		}
		let decrypted = try signalingServerEncryption.decrypt(data: rpcMessage.encryptedPayload.data)
		let primitive = try _decodeWebRTCPrimitive(method: rpcMessage.method, data: decrypted)
		return primitive
	}
}

@Sendable
public func _decodeWebRTCPrimitive(
	method: RPCMethod,
	data: Data
) throws -> WebRTCPrimitive {
	try _decodeWebRTCPrimitive(method: method, data: data, jsonDecoder: .init())
}

@Sendable
public func _decodeWebRTCPrimitive(
	method: RPCMethod,
	data: Data,
	jsonDecoder: JSONDecoder
) throws -> WebRTCPrimitive {
	switch method {
	case .offer:
		return try .offer(jsonDecoder.decode(WebRTCOffer.self, from: data))
	case .answer:
		return try .answer(jsonDecoder.decode(WebRTCAnswer.self, from: data))
	case .iceCandidate:
		return try .iceCandidate(jsonDecoder.decode(WebRTCICECandidate.self, from: data))
	}
}

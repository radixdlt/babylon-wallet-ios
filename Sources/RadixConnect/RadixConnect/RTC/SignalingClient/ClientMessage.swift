import Foundation
import Prelude
import RadixConnectModels

// MARK: - SignalingClient.ClientMessage
extension SignalingClient {
	/// Describes the DTO exchanged between clients during WebRTC negotiation
	struct ClientMessage: Sendable, Equatable {
		let requestId: RequestID
		/// The ID of the client to whom to send the message
		let targetClientId: RemoteClientID
		/// The message payload
		let primitive: RTCPrimitive
	}
}

// MARK: - SignalingClient.ClientMessage.RequestID
extension SignalingClient.ClientMessage {
	typealias RequestID = Tagged<Self, String>

	enum Method: String, Sendable, Codable, Equatable {
		case offer
		case answer
		case iceCandidate

		init(from primitive: RTCPrimitive) {
			switch primitive {
			case .offer:
				self = .offer
			case .answer:
				self = .answer
			case .iceCandidate:
				self = .iceCandidate
			}
		}
	}
}

// MARK: - SignalingClient.ClientMessage + Codable
extension SignalingClient.ClientMessage: Codable {
	enum CodingKeys: String, CodingKey {
		case requestId, method, targetClientId, encryptedPayload
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		self.requestId = try container.decode(RequestID.self, forKey: .requestId)
		self.targetClientId = try container.decode(RemoteClientID.self, forKey: .targetClientId)

		// Extract the pre-configured EncryptionKey to be used to decode the payload
		let encryptionKey = decoder.userInfo[.clientMessageEncryptonKey] as! SignalingClient.EncryptionKey
		let encryptedPayload = try container.decode(HexCodable.self, forKey: .encryptedPayload)
		let decryptedPyload = try encryptionKey.decrypt(data: encryptedPayload.data)
		let method = try container.decode(Method.self, forKey: .method)

		// Based on the method, decode to specific RTCPrimitive
		switch method {
		case .offer:
			self.primitive = try .offer(JSONDecoder().decode(RTCPrimitive.Offer.self, from: decryptedPyload))
		case .answer:
			self.primitive = try .answer(JSONDecoder().decode(RTCPrimitive.Answer.self, from: decryptedPyload))
		case .iceCandidate:
			self.primitive = try .iceCandidate(JSONDecoder().decode(RTCPrimitive.ICECandidate.self, from: decryptedPyload))
		}
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		try container.encode(requestId, forKey: .requestId)
		try container.encode(targetClientId, forKey: .targetClientId)

		// Extract the pre-configured EncryptionKey to be used to decode the payload
		let encryptionKey = encoder.userInfo[.clientMessageEncryptonKey] as! SignalingClient.EncryptionKey
		let encodedPrimitive = try JSONEncoder().encode(primitive)
		let encryptedPrimitive = try encryptionKey.encrypt(data: encodedPrimitive)
		let payload = HexCodable(data: encryptedPrimitive)
		try container.encode(payload, forKey: .encryptedPayload)

		switch primitive {
		case .offer:
			try container.encode(Method.offer, forKey: .method)
		case .answer:
			try container.encode(Method.answer, forKey: .method)
		case .iceCandidate:
			try container.encode(Method.iceCandidate, forKey: .method)
		}
	}
}

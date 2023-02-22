// MARK: - ClientMessage
import Foundation

struct RemoteData: Equatable, Sendable {
        let remoteClientId: ClientID
        let message: ClientMessage
}

extension RemoteData {
        var offer: IdentifiedPrimitive<RTCPrimitive.Offer>? {
                guard let offer = message.primitive.offer else {
                        return nil
                }
                return .init(content: offer, id: remoteClientId)
        }

        var answer: IdentifiedPrimitive<RTCPrimitive.Answer>? {
                guard let answer = message.primitive.answer else {
                        return nil
                }
                return .init(content: answer, id: remoteClientId)
        }

        var iceCandidate: IdentifiedPrimitive<RTCPrimitive.ICECandidate>? {
                guard let candidate = message.primitive.iceCandidate else {
                        return nil
                }
                return .init(content: candidate, id: remoteClientId)
        }
}

struct ClientMessage: Sendable, Equatable {
        enum Method: String, Sendable, Codable, Equatable {
                case offer
                case answer
                case iceCandidate
        }

        let requestId: RequestID
        let targetClientId: ClientID
        let primitive: RTCPrimitive
}

extension ClientMessage: Decodable {
        enum CodingKeys: String, CodingKey {
                case requestId, method, targetClientId, encryptedPayload
        }

        init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)

                self.requestId = try container.decode(RequestID.self, forKey: .requestId)
                self.targetClientId = try container.decode(ClientID.self, forKey: .targetClientId)

                let encryptedPayload = try container.decode(EncryptedPayload.self, forKey: .encryptedPayload)
                let encryptionKey = decoder.userInfo[.clientMessageEncryptonKey] as! EncryptionKey
                let decryptedPyload = try encryptionKey.decrypt(data: encryptedPayload.data)
                let method = try container.decode(Method.self, forKey: .method)

                switch method {
                case .offer:
                        self.primitive = .offer(try JSONDecoder().decode(RTCPrimitive.Offer.self, from: decryptedPyload))
                case .answer:
                        self.primitive = .answer(try JSONDecoder().decode(RTCPrimitive.Answer.self, from: decryptedPyload))
                case .iceCandidate:
                        self.primitive = .iceCandidate(try JSONDecoder().decode(RTCPrimitive.ICECandidate.self, from: decryptedPyload))
                }
        }
}

extension ClientMessage: Encodable {
        func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)

                try container.encode(requestId, forKey: .requestId)
                try container.encode(targetClientId, forKey: .targetClientId)

                let encodedPrimitive = try JSONEncoder().encode(primitive)
                let encryptionKey = encoder.userInfo[.clientMessageEncryptonKey] as! EncryptionKey
                let encryptedPrimitive = try encryptionKey.encrypt(data: encodedPrimitive)
                let payload = EncryptedPayload(rawValue: .init(data: encryptedPrimitive))
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


extension ClientMessage.Method {
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

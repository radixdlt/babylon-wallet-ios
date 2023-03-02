import Foundation
@testable import RadixConnect

extension IncommingMessage.FromSignalingServer.ResponseForRequest {
	var json: JSONValue {
		switch self {
		case let .success(value):
			return .dictionary([
				"info": .string("confirmation"),
				"requestId": .string(value.rawValue),
			])
		case .failure:
			return .dictionary([
				"info": .string("missingRemoteClientError"),
				"requestId": .string(self.requestId!.rawValue),
			])
		}
	}
}

extension RTCPrimitive.Offer {
	var payload: JSONValue {
		JSONValue.dictionary([
			"sdp": .string(sdp.rawValue),
		])
	}
}

extension RTCPrimitive.Answer {
	var payload: JSONValue {
		JSONValue.dictionary([
			"sdp": .string(sdp.rawValue),
		])
	}
}

extension RTCPrimitive.ICECandidate {
	var payload: JSONValue {
		JSONValue.dictionary([
			"candidate": .string(candidate.rawValue),
			"sdpMLineIndex": .int32(sdpMLineIndex),
			"sdpMid": .string(sdpMid!),
		])
	}
}

extension RTCPrimitive {
	var payload: JSONValue {
		switch self {
		case let .offer(offer):
			return offer.payload
		case let .answer(answer):
			return answer.payload
		case let .iceCandidate(iceCandidate):
			return iceCandidate.payload
		}
	}
}

extension IncommingMessage.FromSignalingServer.Notification {
	var payload: JSONValue {
		let infoKey: String = {
			switch self {
			case .remoteClientJustConnected:
				return "remoteClientJustConnected"
			case .remoteClientDisconnected:
				return "remoteClientDisconnected"
			case .remoteClientIsAlreadyConnected:
				return "remoteClientIsAlreadyConnected"
			}
		}()

		return .dictionary([
			"info": .string(infoKey),
			"remoteClientId": .string(remoteClientId.rawValue),
		])
	}
}

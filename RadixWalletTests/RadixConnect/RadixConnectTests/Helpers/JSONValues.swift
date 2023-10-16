import Foundation
@testable import RadixConnect
import TestingPrelude

extension SignalingClient.IncomingMessage.FromSignalingServer.ResponseForRequest {
	var json: JSONValue {
		switch self {
		case let .success(value):
			.dictionary([
				"info": .string("confirmation"),
				"requestId": .string(value.rawValue),
			])
		case .failure:
			.dictionary([
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
			offer.payload
		case let .answer(answer):
			answer.payload
		case let .iceCandidate(iceCandidate):
			iceCandidate.payload
		}
	}
}

extension SignalingClient.IncomingMessage.FromSignalingServer.Notification {
	var payload: JSONValue {
		let infoKey = switch self {
		case .remoteClientJustConnected:
			"remoteClientJustConnected"
		case .remoteClientDisconnected:
			"remoteClientDisconnected"
		case .remoteClientIsAlreadyConnected:
			"remoteClientIsAlreadyConnected"
		}

		return .dictionary([
			"info": .string(infoKey),
			"remoteClientId": .string(remoteClientId.rawValue),
		])
	}
}

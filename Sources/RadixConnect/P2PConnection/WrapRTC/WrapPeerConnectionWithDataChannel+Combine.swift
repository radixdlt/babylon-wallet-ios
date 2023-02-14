import Combine
import P2PModels
import Prelude

extension WrapPeerConnectionWithDataChannel {
	public func createOffer() -> Future<WebRTCOffer, ConverseError.WebRTC> {
		let connectionID = self.connectionID
		return Future { [weak self] promise in
			guard let self = self else {
				let error = ConverseError.WebRTC.failedToCreateOfferSelfIsNil(connection: connectionID)
				loggerGlobal.error("WrapRTC failed to create offer, self is nil.")
				promise(.failure(error))
				return
			}
			self.createOffer { result in
				promise(result)
			}
		}
	}

	public func setRemoteOffer(_ offer: WebRTCOffer) -> Future<Void, ConverseError.WebRTC> {
		let connectionID = self.connectionID
		return Future { [weak self] promise in
			guard let self = self else {
				let error = ConverseError.WebRTC.failedToSetRemoteOfferSelfIsNil(connection: connectionID)
				loggerGlobal.error("WrapRTC failed to set remote offer, self is nil.")
				promise(.failure(error))
				return
			}
			self.setRemote(offer: offer) { result in
				promise(result)
			}
		}
	}

	public func setRemoteAnswer(_ answer: WebRTCAnswer) -> Future<Void, ConverseError.WebRTC> {
		let connectionID = self.connectionID
		return Future { [weak self] promise in
			guard let self = self else {
				let error = ConverseError.WebRTC.failedToSetRemoteAnswerSelfIsNil(connection: connectionID)
				loggerGlobal.error("WrapRTC failed to set remote answer, self is nil.")
				promise(.failure(error))
				return
			}
			self.setRemote(answer: answer) { result in
				promise(result)
			}
		}
	}

	public func setRemoteICECandidate(_ iceCandidate: WebRTCICECandidate) -> Future<Void, ConverseError.WebRTC> {
		let connectionID = self.connectionID
		return Future { [weak self] promise in
			guard let self = self else {
				let error = ConverseError.WebRTC.failedToAddRemoteICECandidateSelfIsNil(connection: connectionID)
				loggerGlobal.error("WrapRTC failed to add remote ICE candidate, self is nil.")
				promise(.failure(error))
				return
			}
			self.setRemote(iceCandidate: iceCandidate) { result in
				promise(result)
			}
		}
	}
}

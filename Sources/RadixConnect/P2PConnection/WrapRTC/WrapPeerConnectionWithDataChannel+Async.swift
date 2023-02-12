import Combine
import P2PModels
import Prelude
import WebRTC

extension WrapPeerConnectionWithDataChannel {
	/// Used when we receive an RTC ANSWER from remote client
	private func _set(
		remoteSdp: RTCSessionDescription
	) async throws {
		let connectionID = connectionID
		try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<Void, Swift.Error>) in
			guard let self = self else {
				continuation.resume(throwing: ConverseError.webRTC(.failedToSetRemoteSDPDescriptionSelfIsNil(connection: connectionID)))
				return
			}
			self.__set(remoteSdp: remoteSdp) { result in
				continuation.resume(with: result)
			}
		}
	}

	private func _set(
		remoteICECandidate: RTCIceCandidate
	) async throws {
		let connectionID = connectionID
		try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<Void, Swift.Error>) in
			guard let self = self else {
				continuation.resume(throwing: ConverseError.webRTC(.failedToAddRemoteICECandidateSelfIsNil(connection: connectionID)))
				return
			}
			self.__set(remoteICECandidate: remoteICECandidate) { result in
				continuation.resume(with: result)
			}
		}
	}
}

extension WrapPeerConnectionWithDataChannel {
	public func setRemoteOffer(_ offer: WebRTCOffer) async throws {
		try await _set(remoteSdp: offer.rtcSessionDescription())
	}

	public func setRemoteAnswer(_ answer: WebRTCAnswer) async throws {
		try await _set(remoteSdp: answer.rtcSessionDescription())
	}

	public func setRemoteICECandidate(_ iceCandidate: WebRTCICECandidate) async throws {
		try await _set(remoteICECandidate: iceCandidate.rtc())
	}

	public func createOffer() async throws -> WebRTCOffer {
		let connectionID = self.connectionID
		return try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<WebRTCOffer, Error>) in
			guard let self = self else {
				let error = ConverseError.webRTC(.failedToCreateOfferSelfIsNil(connection: connectionID))
				loggerGlobal.error("WrapRTC failed to create offer, self is nil.")
				continuation.resume(throwing: error)
				return
			}
			self.createOffer { result in
				continuation.resume(with: result)
			}
		}
	}
}

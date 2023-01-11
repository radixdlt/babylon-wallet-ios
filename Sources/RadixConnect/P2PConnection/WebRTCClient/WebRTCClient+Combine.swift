import Foundation
import P2PModels

// MARK: Combine
import Combine
public extension WebRTCClient {
	func creatingOffer() -> AnyPublisher<WebRTCOffer, ConverseError> {
		guard let wrapped else {
			return Fail(error: ConverseError.webRTC(.wrappedPeerConnectionAndChannelIsNilProbablySinceCloseHasBeenCalled)
			).eraseToAnyPublisher()
		}
		return wrapped.createOffer()
			.mapError { ConverseError.webRTC($0) }
			.eraseToAnyPublisher()
	}

	func settingRemoteAnswer(_ answer: WebRTCAnswer) -> AnyPublisher<Void, ConverseError> {
		guard let wrapped else {
			return Fail(error: ConverseError.webRTC(.wrappedPeerConnectionAndChannelIsNilProbablySinceCloseHasBeenCalled)
			).eraseToAnyPublisher()
		}
		return wrapped.setRemoteAnswer(answer)
			.mapError { ConverseError.webRTC($0) }
			.eraseToAnyPublisher()
	}

	func settingRemoteICECandidate(_ iceCandidate: WebRTCICECandidate) -> AnyPublisher<Void, ConverseError> {
		guard let wrapped else {
			return Fail(error: ConverseError.webRTC(.wrappedPeerConnectionAndChannelIsNilProbablySinceCloseHasBeenCalled)
			).eraseToAnyPublisher()
		}
		return wrapped.setRemoteICECandidate(iceCandidate)
			.mapError { ConverseError.webRTC($0) }
			.eraseToAnyPublisher()
	}
}

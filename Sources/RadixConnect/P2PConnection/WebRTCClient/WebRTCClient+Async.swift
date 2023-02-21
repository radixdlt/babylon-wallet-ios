import Foundation
import P2PModels

// MARK: Async
extension WebRTCClient {
	public func createOffer() async throws -> WebRTCOffer {
		guard let wrapped else {
			throw ConverseError.WebRTC.wrappedPeerConnectionAndChannelIsNilProbablySinceCloseHasBeenCalled
		}
		return try await wrapped.createOffer()
	}

	public func setRemoteAnswer(_ answer: WebRTCAnswer) async throws {
		guard let wrapped else {
			throw ConverseError.WebRTC.wrappedPeerConnectionAndChannelIsNilProbablySinceCloseHasBeenCalled
		}
		try await wrapped.setRemoteAnswer(answer)
	}

	public func setRemoteICECandidate(_ iceCandidate: WebRTCICECandidate) async throws {
		guard let wrapped else {
			throw ConverseError.WebRTC.wrappedPeerConnectionAndChannelIsNilProbablySinceCloseHasBeenCalled
		}
		try await wrapped.setRemoteICECandidate(iceCandidate)
	}
}

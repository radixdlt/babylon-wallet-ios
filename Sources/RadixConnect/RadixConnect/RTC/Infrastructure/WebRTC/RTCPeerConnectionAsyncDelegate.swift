import Foundation
import Prelude
import WebRTC

// MARK: - RTCPeerConnectionAsyncDelegate
final class RTCPeerConnectionAsyncDelegate:
	NSObject,
	Sendable,
	PeerConnectionDelegate
{
	let onNegotiationNeeded: AsyncStream<Void>
	let onIceConnectionStateSubject: AsyncCurrentValueSubject<ICEConnectionState> = .init(.new)

	/// A multicasting async sequence of ICE Connection state updates which *replays* the last value.
	var onIceConnectionState: AnyAsyncSequence<ICEConnectionState> {
		onIceConnectionStateSubject.share().eraseToAnyAsyncSequence()
	}

	let onSignalingState: AsyncStream<SignalingState>
	let onGeneratedICECandidate: AsyncStream<RTCPrimitive.ICECandidate>

	private let onNegotiationNeededContinuation: AsyncStream<Void>.Continuation

	private let onSignalingStateContinuation: AsyncStream<SignalingState>.Continuation
	private let onGeneratedICECandidateContinuation: AsyncStream<RTCPrimitive.ICECandidate>.Continuation

	override init() {
		(onNegotiationNeeded, onNegotiationNeededContinuation) = AsyncStream.streamWithContinuation()

		(onSignalingState, onSignalingStateContinuation) = AsyncStream.streamWithContinuation()
		(onGeneratedICECandidate, onGeneratedICECandidateContinuation) = AsyncStream.streamWithContinuation()

		super.init()
	}

	func cancel() {
		onNegotiationNeededContinuation.finish()
		onIceConnectionStateSubject.send(.finished)
		onSignalingStateContinuation.finish()
		onGeneratedICECandidateContinuation.finish()
	}
}

// MARK: RTCPeerConnectionDelegate
extension RTCPeerConnectionAsyncDelegate: RTCPeerConnectionDelegate {
	func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
		onNegotiationNeededContinuation.yield(())
	}

	func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
		onSignalingStateContinuation.yield(.init(from: stateChanged))
	}

	func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
		onIceConnectionStateSubject.send(.init(from: newState))
	}

	func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
		onGeneratedICECandidateContinuation.yield(.init(from: candidate))
	}

	// IGNORED - below events are ignored
	func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
		loggerGlobal.trace("\(Self.self).\(#function) is ignored")
	}

	func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
		loggerGlobal.trace("\(Self.self).\(#function) is ignored")
	}

	func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
		loggerGlobal.trace("\(Self.self).\(#function) is ignored")
		loggerGlobal.trace("RTCPeerConnection did remove ICECandidates")
	}

	func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
		loggerGlobal.trace("\(Self.self).\(#function) is ignored")
		loggerGlobal.trace("RTCPeerConnection did open DataChannel \(dataChannel.channelId)")
	}

	func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
		loggerGlobal.trace("\(Self.self).\(#function) is ignored")
		loggerGlobal.trace("RTCPeerConnection did change ICEGatheringState to \(newState)")
	}
}

private extension SignalingState {
	init(from rtc: RTCSignalingState) {
		switch rtc {
		case .closed: self = .closed
		case .stable: self = .stable
		case .haveLocalOffer: self = .haveLocalOffer
		case .haveLocalPrAnswer: self = .haveLocalPrAnswer
		case .haveRemoteOffer: self = .haveRemoteOffer
		case .haveRemotePrAnswer: self = .haveRemotePrAnswer
		@unknown default:
			fatalError("Unknown signalingState: \(rtc)")
		}
	}
}

private extension ICEConnectionState {
	init(from rtc: RTCIceConnectionState) {
		switch rtc {
		case .new: self = .new
		case .checking: self = .checking
		case .connected: self = .connected
		case .completed: self = .completed
		case .failed: self = .failed
		case .disconnected: self = .disconnected
		case .closed: self = .closed
		case .count:
			fatalError()
		@unknown default:
			fatalError()
		}
	}
}

private extension RTCPrimitive.ICECandidate {
	init(from rtc: RTCIceCandidate) {
		self.init(
			sdp: .init(rtc.sdp),
			sdpMLineIndex: rtc.sdpMLineIndex,
			sdpMid: rtc.sdpMid
		)
	}
}

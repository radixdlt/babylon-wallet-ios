import Foundation
import WebRTC

// MARK: - PeerConnectionDelegate
final class RTCPeerConnectionAsyncDelegate:
        NSObject,
        Sendable,
        PeerConnectionDelegate
{
        let onNegotiationNeeded: AsyncStream<Void>
        let onIceConnectionState: AsyncStream<ICEConnectionState>
        let onSignalingState: AsyncStream<SignalingState>
        let onGeneratedICECandidate: AsyncStream<RTCPrimitive.ICECandidate>

        private let onNegotiationNeededContinuation: AsyncStream<Void>.Continuation
        private let onIceConnectionStateContinuation: AsyncStream<ICEConnectionState>.Continuation
        private let onSignalingStateContinuation: AsyncStream<SignalingState>.Continuation
        private let onGeneratedICECandidateContinuation: AsyncStream<RTCPrimitive.ICECandidate>.Continuation

        internal override init() {
                (onNegotiationNeeded, onNegotiationNeededContinuation) = AsyncStream.streamWithContinuation(Void.self)
                (onIceConnectionState, onIceConnectionStateContinuation) = AsyncStream.streamWithContinuation(ICEConnectionState.self)
                (onSignalingState, onSignalingStateContinuation) = AsyncStream.streamWithContinuation(SignalingState.self)
                (onGeneratedICECandidate, onGeneratedICECandidateContinuation) = AsyncStream.streamWithContinuation(RTCPrimitive.ICECandidate.self)

                super.init()
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
                onIceConnectionStateContinuation.yield(.init(from: newState))
        }

        func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
                onGeneratedICECandidateContinuation.yield(.init(from: candidate))
        }

        // IGNORED - below events are ignored
        func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {}
        func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}
        func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
        func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {}
        func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
}

fileprivate extension SignalingState {
        init(from rtc: RTCSignalingState) {
                switch rtc {
                case .closed: self = .closed
                case .stable: self = .stable
                case .haveLocalOffer: self = .haveLocalOffer
                case .haveLocalPrAnswer: self =  .haveLocalPrAnswer
                case .haveRemoteOffer: self = .haveRemoteOffer
                case .haveRemotePrAnswer: self = .haveRemotePrAnswer
                @unknown default:
                        fatalError("Unknown signalingState: \(rtc)")
                }

        }
}

fileprivate extension ICEConnectionState {
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

fileprivate  extension RTCPrimitive.ICECandidate {
        init(from rtc: RTCIceCandidate) {
                self.init(
                        sdp: .init(rtc.sdp),
                        sdpMLineIndex: rtc.sdpMLineIndex,
                        sdpMid: rtc.sdpMid,
                        serverUrl: rtc.serverUrl
                )
        }
}

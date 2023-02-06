import Foundation

struct PeerConnectionClient {
        let peerConnection: PeerConnection
        let delegate: PeerConnectionDelegate


        func onRemoteAnswer(_ answer: RTCPrimitive.Answer) async throws {
                try await peerConnection.setRemoteAnswer(answer)
        }

        func createOffer() async throws -> RTCPrimitive.Offer {
                let offer = try await peerConnection.createLocalOffer()
                try await peerConnection.setLocalOffer(offer)
                return offer
        }

        func onRemoteICECandidate(_ candidate: RTCPrimitive.ICECandidate) async throws {
                try await peerConnection.addRemoteICECandidate(candidate)
        }
}

extension PeerConnectionClient {
        var onNegotiationNeeded: AsyncStream<Void> {
                delegate.onNegotiationNeeded
        }
        var onIceConnectionState: AsyncStream<ICEConnectionState> {
                delegate.onIceConnectionState
        }
        var onSignalingState: AsyncStream<SignalingState> {
                delegate.onSignalingState
        }

        var onGeneratedICECandidate: AsyncStream<RTCPrimitive.ICECandidate> {
                delegate.onGeneratedICECandidate
        }
}

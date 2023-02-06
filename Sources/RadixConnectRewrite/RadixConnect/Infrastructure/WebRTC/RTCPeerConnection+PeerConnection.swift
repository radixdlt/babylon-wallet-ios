import WebRTC

struct WebRTCFactory {
        static let factory: RTCPeerConnectionFactory = {
            RTCInitializeSSL()
            let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
            let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
            return RTCPeerConnectionFactory(
                encoderFactory: videoEncoderFactory,
                decoderFactory: videoDecoderFactory
            )
        }()

        static let ICEServers: [RTCIceServer] = [
                RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"]),
                RTCIceServer(urlStrings: ["stun:stun1.l.google.com:19302"]),
                RTCIceServer(urlStrings: ["stun:stun2.l.google.com:19302"]),
                RTCIceServer(urlStrings: ["stun:stun3.l.google.com:19302"]),
                RTCIceServer(urlStrings: ["stun:stun4.l.google.com:19302"])
        ]

        static let peerConnectionConfig: RTCConfiguration = {
                let config = RTCConfiguration()
                config.sdpSemantics = .unifiedPlan
                config.continualGatheringPolicy = .gatherContinually
                config.iceServers = ICEServers

                return config
        }()

        static let dataChannelConfig: RTCDataChannelConfiguration = {
                let config = RTCDataChannelConfiguration()
                config.isNegotiated = true
                config.isOrdered = true
                config.channelId = 0
                return config

        }()

        // Define media constraints. DtlsSrtpKeyAgreement is required to be true to be able to connect with web browsers.
        static let peerConnectionConstraints = RTCMediaConstraints(
                mandatoryConstraints: nil,
                optionalConstraints: [
                        "DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue,
                ]
        )

        static func makeRTCPeerConnection(delegate: RTCPeerConnectionDelegate) -> PeerConnection? {
                return factory.peerConnection(with: peerConnectionConfig,
                                       constraints: peerConnectionConstraints,
                                       delegate: delegate)
        }
}


extension RTCPeerConnection: PeerConnection {
        struct FailedToCreateDataChannel: Error {}

        func createDataChannel() throws -> DataChannelClient {
                let config = WebRTCFactory.dataChannelConfig
                guard let dataChannel = dataChannel(forLabel: "\(config.channelId)", configuration: config) else {
                        throw FailedToCreateDataChannel()
                }
                let delegate = RTCDataChannelAsyncDelegate()
                dataChannel.delegate = delegate
                return DataChannelClient(dataChannel: dataChannel, delegate: delegate)
        }

        func setLocalOffer(_ offer: RTCPrimitive.Offer) async throws {
                try await setLocalDescription(.init(from: offer))
        }

        func setRemoteAnswer(_ answer: RTCPrimitive.Answer) async throws {
                try await setLocalDescription(.init(from: answer))
        }

        func createLocalOffer() async throws -> RTCPrimitive.Offer {
                .init(from: try await self.offer(for: .negotiationConstraints))
        }

        func createLocalAnswer() async throws -> RTCPrimitive.Answer {
                .init(from: try await self.answer(for: .negotiationConstraints))
        }

        func addRemoteICECandidate(_ candidate: RTCPrimitive.ICECandidate) async throws {
                try await self.add(.init(from: candidate))
        }
}

extension RTCDataChannel: @unchecked Sendable {}

extension RTCDataChannel: DataChannel {
        func sendData(_ data: Data) {
                self.sendData(.init(data: data, isBinary: true))
        }
}

extension RTCMediaConstraints {
        static var negotiationConstraints: RTCMediaConstraints {
                .init(mandatoryConstraints: [:], optionalConstraints: [:])
        }
}

extension RTCPrimitive.Offer {
        init(from sessionDescription: RTCSessionDescription) {
                self.init(sdp: .init(rawValue: sessionDescription.sdp))
        }
}

extension RTCPrimitive.Answer {
        init(from sessionDescription: RTCSessionDescription) {
                self.init(sdp: .init(rawValue: sessionDescription.sdp))
        }
}

extension RTCSessionDescription {
        convenience init(from offer: RTCPrimitive.Offer) {
                self.init(type: .offer, sdp: offer.sdp.rawValue)
        }

        convenience init(from answer: RTCPrimitive.Answer) {
                self.init(type: .answer, sdp: answer.sdp.rawValue)
        }
}

extension RTCIceCandidate {
        convenience init(from candidate: RTCPrimitive.ICECandidate) {
                self.init(sdp: candidate.sdp.rawValue, sdpMLineIndex: candidate.sdpMLineIndex, sdpMid: candidate.sdpMid)
        }
}

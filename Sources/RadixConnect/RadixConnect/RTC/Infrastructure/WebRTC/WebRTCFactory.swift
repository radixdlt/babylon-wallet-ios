import WebRTC
import Foundation

// MARK: - WebRTCFactory
struct WebRTCFactory: PeerConnectionFactory {
        struct FailedToCreatePeerConnectionError: Error {}

        static let factory: RTCPeerConnectionFactory = {
                RTCInitializeSSL()
                let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
                let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
                return RTCPeerConnectionFactory(
                        encoderFactory: videoEncoderFactory,
                        decoderFactory: videoDecoderFactory
                )
        }()

        static let turnServers: [RTCIceServer] = {
                #if DEBUG
                [
                        RTCIceServer(urlStrings: ["turn:turn-dev-udp.rdx-works-main.extratools.works:80?transport=udp"], username: "username", credential: "password", tlsCertPolicy: .insecureNoCheck),
                        RTCIceServer(urlStrings: ["turn:turn-betanet-udp.radixdlt.com:80?transport=tcp"], username: "username", credential: "password", tlsCertPolicy: .insecureNoCheck),
                ]
                #else
                [
                        RTCIceServer(urlStrings: ["turn:turn-dev-udp.rdx-works-main.extratools.works:80?transport=udp"], username: "username", credential: "password", tlsCertPolicy: .insecureNoCheck),
                        RTCIceServer(urlStrings: ["turn:turn-betanet-udp.radixdlt.com:80?transport=tcp"], username: "username", credential: "password", tlsCertPolicy: .insecureNoCheck),
                ]
                #endif
        }()

        static let ICEServers: [RTCIceServer] = [
                RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"]),
                RTCIceServer(urlStrings: ["stun:stun1.l.google.com:19302"]),
                RTCIceServer(urlStrings: ["stun:stun2.l.google.com:19302"]),
                RTCIceServer(urlStrings: ["stun:stun3.l.google.com:19302"]),
                RTCIceServer(urlStrings: ["stun:stun4.l.google.com:19302"]),
        ] + turnServers

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

        static func makeRTCPeerConnection(delegate: RTCPeerConnectionDelegate) throws -> PeerConnection {
                guard let peerConnection = factory.peerConnection(with: peerConnectionConfig,
                                                                  constraints: peerConnectionConstraints,
                                                                  delegate: delegate)
                else {
                        throw FailedToCreatePeerConnectionError()
                }

                return peerConnection
        }

        func makePeerConnectionClient(for clientId: RemoteClientID) throws -> PeerConnectionClient {
                let delegate = RTCPeerConnectionAsyncDelegate()
                let peerConnection = try Self.makeRTCPeerConnection(delegate: delegate)
                return try .init(id: .init(clientId.rawValue), peerConnection: peerConnection, delegate: delegate)
        }
}

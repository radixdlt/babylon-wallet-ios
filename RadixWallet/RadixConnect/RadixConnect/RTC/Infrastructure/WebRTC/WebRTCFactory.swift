import Sargon
import WebRTC

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

	static func peerConnectionConfig(
		iceServers: [P2PIceServer]
	) -> RTCConfiguration {
		let config = RTCConfiguration()
		config.sdpSemantics = .unifiedPlan
		config.continualGatheringPolicy = .gatherContinually
		config.iceServers = iceServers.map {
			RTCIceServer(
				urlStrings: $0.urls,
				username: $0.username,
				credential: $0.credential,
				tlsCertPolicy: .insecureNoCheck
			)
		}

		return config
	}

	static let dataChannelConfig: RTCDataChannelConfiguration = {
		let config = RTCDataChannelConfiguration()
		config.isNegotiated = true
		config.isOrdered = true
		config.channelId = 0
		return config

	}()

	/// Define media constraints. DtlsSrtpKeyAgreement is required to be true to be able to connect with web browsers.
	static let peerConnectionConstraints = RTCMediaConstraints(
		mandatoryConstraints: nil,
		optionalConstraints: [
			"DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue,
		]
	)

	func makePeerConnectionClient(
		for clientId: RemoteClientID,
		using iceServers: [P2PIceServer]
	) throws -> PeerConnectionClient {
		let delegate = RTCPeerConnectionAsyncDelegate()
		guard let peerConnection = Self.factory.peerConnection(
			with: Self.peerConnectionConfig(iceServers: iceServers),
			constraints: Self.peerConnectionConstraints,
			delegate: delegate
		) else {
			throw FailedToCreatePeerConnectionError()
		}
		return try .init(id: .init(clientId.rawValue), peerConnection: peerConnection, delegate: delegate)
	}
}

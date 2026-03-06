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
		transportProfile: P2PTransportProfile
	) -> RTCConfiguration {
		let config = RTCConfiguration()
		config.sdpSemantics = .unifiedPlan
		config.continualGatheringPolicy = .gatherContinually

		let stunIceServers: [RTCIceServer] = if transportProfile.stun.urls.isEmpty {
			[]
		} else {
			[
				RTCIceServer(
					urlStrings: transportProfile.stun.urls,
					username: nil,
					credential: nil,
					tlsCertPolicy: .insecureNoCheck
				),
			]
		}

		let turnIceServers: [RTCIceServer] = if transportProfile.turn.urls.isEmpty {
			[]
		} else {
			[
				RTCIceServer(
					urlStrings: transportProfile.turn.urls,
					username: transportProfile.turn.username,
					credential: transportProfile.turn.credential,
					tlsCertPolicy: .insecureNoCheck
				),
			]
		}

		config.iceServers = stunIceServers + turnIceServers

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
		using transportProfile: P2PTransportProfile
	) throws -> PeerConnectionClient {
		let delegate = RTCPeerConnectionAsyncDelegate()
		guard let peerConnection = Self.factory.peerConnection(
			with: Self.peerConnectionConfig(transportProfile: transportProfile),
			constraints: Self.peerConnectionConstraints,
			delegate: delegate
		) else {
			throw FailedToCreatePeerConnectionError()
		}
		return try .init(id: .init(clientId.rawValue), peerConnection: peerConnection, delegate: delegate)
	}
}

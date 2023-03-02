import WebRTC
import RadixConnectModels

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

	static let ICEServers: [RTCIceServer] = [
		RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"]),
		RTCIceServer(urlStrings: ["stun:stun1.l.google.com:19302"]),
		RTCIceServer(urlStrings: ["stun:stun2.l.google.com:19302"]),
		RTCIceServer(urlStrings: ["stun:stun3.l.google.com:19302"]),
		RTCIceServer(urlStrings: ["stun:stun4.l.google.com:19302"]),
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
                return try .init(id: .init(clientId), peerConnection: peerConnection, delegate: delegate)
	}
}

// MARK: - RTCPeerConnection + PeerConnection
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

	func setLocalAnswer(_ answer: RTCPrimitive.Answer) async throws {
		try await setLocalDescription(.init(from: answer))
	}

	func setRemoteOffer(_ offer: RTCPrimitive.Offer) async throws {
		try await setRemoteDescription(.init(from: offer))
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

	func setRemoteAnswer(_ answer: RTCPrimitive.Answer) async throws {
		try await setRemoteDescription(.init(from: answer))
	}

	func createOffer() async throws -> RTCPrimitive.Offer {
		try await .init(from: offer(for: .negotiationConstraints))
	}

	func setLocalOffer(_ offer: RTCPrimitive.Offer) async throws {
		try await setLocalDescription(.init(from: offer))
	}
}

// MARK: - RTCDataChannel + Sendable
extension RTCDataChannel: @unchecked Sendable {}

// MARK: - RTCDataChannel + DataChannel
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

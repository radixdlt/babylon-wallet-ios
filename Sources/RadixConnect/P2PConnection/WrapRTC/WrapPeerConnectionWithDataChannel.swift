import Collections
import P2PModels
import WebRTC

// MARK: - WrapPeerConnectionWithDataChannel
public final class WrapPeerConnectionWithDataChannel {
	internal let connectionID: P2PConnectionID
	private let webRTCConfig: WebRTCConfig

	// MARK: RTC

	private let peerConnection: RTCPeerConnection

	private let peerConnectionDelegate: WrapRTCPeerConnectionDelegate

	private let dataChannel: RTCDataChannel
	private let dataChannelDelegate: WrapRTCDataChannelDelegate

	public init(
		connectionID: P2PConnectionID,
		webRTCConfig: WebRTCConfig,
		peerConnectionDelegate webRTCPeerConnectionDelegate: WebRTCPeerConnectionDelegate,
		dataChannelDelegate webRTCDataChannelDelegate: WebRTCDataChannelDelegate
	) throws {
		self.connectionID = connectionID
		self.webRTCConfig = webRTCConfig

		// MARK: Create RTCPeerConnection
		let peerConnectionDelegate = WrapRTCPeerConnectionDelegate(
			connectionID: connectionID,
			// WrapRTCPeerConnectionDelegate holds a **weak** ref to webRTCPeerConnectionDelegate
			delegate: webRTCPeerConnectionDelegate
		)
		self.peerConnectionDelegate = peerConnectionDelegate
		self.peerConnection = try Self.createPeerConnection(
			peerConnectionConfig: webRTCConfig.peerConnectionConfig,
			// RTCPeerConnection holds a **weak** ref to delegate
			peerConnectionDelegate: peerConnectionDelegate
		)

		// MARK: Create RTCDataChannel
		let dataChannelDelegate = WrapRTCDataChannelDelegate(
			connectionID: connectionID,
			// WrapRTCDataChannelDelegate holds a **weak** ref to webRTCDataChannelDelegate
			delegate: webRTCDataChannelDelegate
		)
		self.dataChannelDelegate = dataChannelDelegate
		let rtcDataChannel = try Self.createDataChannel(
			peerConnection: peerConnection,
			webRTCDataChannelConfig: webRTCConfig.dataChannelConfig,
			// RTCDataChannel holds a **weak** ref to delegate
			dataChannelDelegate: dataChannelDelegate
		)

		self.dataChannel = rtcDataChannel
	}
}

public extension WrapPeerConnectionWithDataChannel {
	typealias ID = P2PConnectionID
	var id: ID { connectionID }

	func close() {
		dataChannel.delegate = nil
		peerConnection.delegate = nil
		dataChannel.close()
		peerConnection.close()
	}

	func sendDataOverChannel(_ data: Data) throws {
		guard dataChannel.readyState == .open else {
			throw ConverseError.webRTC(.failedToSendDataSinceChannelIsNotOpen(self.webRTCConfig.dataChannelConfig.dataChannelLabelledID))
		}
		loggerGlobal.trace("Sending #\(data.count) bytes over DataChannel (which is open!)")
		dataChannel.sendData(.init(data: data, isBinary: true))
	}

	func dataChannelReadyState() throws -> DataChannelState {
		try DataChannelState(rtcDataChannelState: dataChannel.readyState)
	}
}

private extension WrapPeerConnectionWithDataChannel {
	var mediaConstraints: RTCMediaConstraints {
		.init(
			mandatoryConstraints: [
				kRTCMediaConstraintsIceRestart: kRTCMediaConstraintsValueTrue,
			],
			optionalConstraints: nil
		)
	}

	// The `RTCPeerConnectionFactory` is in charge of creating new RTCPeerConnection instances.
	// A new RTCPeerConnection should be created every new call, but the factory is shared.
	static let connectionFactory: RTCPeerConnectionFactory = {
		RTCInitializeSSL()
		let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
		let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
		return RTCPeerConnectionFactory(
			encoderFactory: videoEncoderFactory,
			decoderFactory: videoDecoderFactory
		)
	}()

	/// Instantiates and configures a new `RTCPeerConnection` with list of config for ICE servers and other configurations.
	static func createPeerConnection(
		peerConnectionConfig: WebRTCPeerConnectionConfig,
		peerConnectionDelegate: WrapRTCPeerConnectionDelegate
	) throws -> RTCPeerConnection {
		let config = RTCConfiguration()

		config.iceServers = peerConnectionConfig.iceServerConfigs.map { (iceServerConfig: ICEServerConfig) -> RTCIceServer in
			let serverURLString = iceServerConfig.url.absoluteString
			if let credentials = iceServerConfig.credentials {
				return RTCIceServer(
					urlStrings: [serverURLString],
					username: credentials.username,
					credential: credentials.password,
					tlsCertPolicy: .insecureNoCheck
				)
			} else {
				return RTCIceServer(urlStrings: [serverURLString])
			}
		}

		config.sdpSemantics = peerConnectionConfig.sdpSemantics.rtc()

		config.continualGatheringPolicy = peerConnectionConfig.continualGatheringPolicy.rtc()

		// Define media constraints. DtlsSrtpKeyAgreement is required to be true to be able to connect with web browsers.
		let constraints = RTCMediaConstraints(
			mandatoryConstraints: nil,
			optionalConstraints: [
				"DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue,
			]
		)

		guard
			let peerConnection = Self.connectionFactory.peerConnection(
				with: config,
				constraints: constraints,
				delegate: peerConnectionDelegate
			)
		else {
			throw ConverseError.webRTC(.failedToCreatePeerConnection(config: peerConnectionConfig))
		}

		return peerConnection
	}

	// Important to create this BEFORE we make an offer.
	static func createDataChannel(
		peerConnection: RTCPeerConnection,
		webRTCDataChannelConfig: WebRTCDataChannelConfig,
		dataChannelDelegate: WrapRTCDataChannelDelegate
	) throws -> RTCDataChannel {
		let configuration = webRTCDataChannelConfig.rtc()

		guard let dataChannel = peerConnection.dataChannel(
			forLabel: webRTCDataChannelConfig.channelLabel.rawValue,
			configuration: configuration
		) else {
			throw ConverseError.webRTC(.failedToCreateDataChannel(config: webRTCDataChannelConfig))
		}
		dataChannel.delegate = dataChannelDelegate
		return dataChannel
	}
}

internal extension WrapPeerConnectionWithDataChannel {
	func __set(
		remoteICECandidate: RTCIceCandidate,
		callback: @escaping SetCallback
	) {
		let connectionID = self.connectionID
		self.peerConnection.add(remoteICECandidate) { maybeError in
			if let error = maybeError {
				let error = ConverseError.WebRTC.failedToAddRemoteICECandidate(underlyingError: error)
				loggerGlobal.error("WrapRTC peer id=\(connectionID) failed to add remote ICE candidate, error: \(error.localizedDescription)")
				callback(.failure(error))
			} else {
				loggerGlobal.debug("WrapRTC peer id=\(connectionID) successfully added remote ICE candidate.")
				callback(.success(()))
			}
		}
	}

	/// Used when we receive an RTC ANSWER from remote client
	func __set(
		remoteSdp: RTCSessionDescription,
		callBack: @escaping SetCallback
	) {
		let connectionID = self.connectionID
		self.peerConnection.setRemoteDescription(remoteSdp, completionHandler: { maybeError in
			if let error = maybeError {
				let error = ConverseError.WebRTC.failedToSetRemoteSDPDescription(underlyingError: error)
				loggerGlobal.error("WrapRTC peer id=\(connectionID) failed to set remote SDP, error: \(error.localizedDescription).")
				callBack(.failure(error))
			} else {
				loggerGlobal.debug("WrapRTC peer id=\(connectionID) successfully set remote SDP (answer).")
				callBack(.success(()))
			}
		})
	}
}

public extension WrapPeerConnectionWithDataChannel {
	func setRemote(
		offer: WebRTCOffer,
		callBack: @escaping SetCallback
	) {
		__set(remoteSdp: offer.rtcSessionDescription(), callBack: callBack)
	}

	func setRemote(
		answer: WebRTCAnswer,
		callBack: @escaping SetCallback
	) {
		__set(remoteSdp: answer.rtcSessionDescription(), callBack: callBack)
	}

	func setRemote(
		iceCandidate: WebRTCICECandidate,
		callback: @escaping SetCallback
	) {
		__set(remoteICECandidate: iceCandidate.rtc(), callback: callback)
	}

	func createOffer(
		callBack: @escaping CreateOfferCallback
	) {
		loggerGlobal.debug("WrapRTC peer id=\(connectionID) creating Offer...")
		let connectionID = self.connectionID
		peerConnection.offer(for: mediaConstraints) { [weak self] sdp, createOfferError in
			guard let self = self else {
				let error = ConverseError.WebRTC.failedToCreateOfferSelfIsNil(connection: connectionID)
				loggerGlobal.error("WrapRTC peer id=\(connectionID) failed to create offer, self is nil.")
				callBack(.failure(error))
				return
			}

			if let createOfferError = createOfferError {
				let failure = ConverseError.WebRTC.failedToCreateOffer(underlyingError: createOfferError)
				callBack(.failure(failure))
			} else if let sdp = sdp {
				self.peerConnection.setLocalDescription(sdp) { updatePeerConnectionWithOfferError in
					if let updatePeerConnectionWithOfferError = updatePeerConnectionWithOfferError {
						let failure = ConverseError.WebRTC.failedToUpdatePeerConnectionWithOffer(underlyingError: updatePeerConnectionWithOfferError)
						loggerGlobal.error("WrapRTC peer id=\(connectionID) failed to update peerConnection with offer, got error: \(failure.localizedDescription)")
						callBack(.failure(failure))
					} else {
						loggerGlobal.debug("WrapRTC peer id=\(connectionID) successfully create Offer and update PeerConnection with it.")
						callBack(.success(WebRTCOffer(rtcSessionDescription: sdp)))
					}
				}
			} else {
				let failure = ConverseError.WebRTC.failedToCreateOfferSDPIsNilAndSoIsError
				loggerGlobal.critical("WrapRTC peer id=\(connectionID) failed to create offer, both SDP and error are nil. Unable to proceed.")
				callBack(.failure(failure))
			}
		}
	}
}

public typealias SetCallback = @Sendable (Result<Void, ConverseError.WebRTC>) -> Void
public typealias CreateOfferCallback = @Sendable (Result<WebRTCOffer, ConverseError.WebRTC>) -> Void
public typealias DiscoverLocalICECandidatesCallback = @Sendable (Result<[WebRTCICECandidate], ConverseError.WebRTC>) -> Void

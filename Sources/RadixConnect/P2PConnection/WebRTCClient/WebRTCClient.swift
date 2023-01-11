import Combine
import P2PModels
import Prelude

// MARK: - WebRTCClient
public final class WebRTCClient: WebRTCPeerConnectionDelegate, WebRTCDataChannelDelegate {
	public let connectionID: P2PConnectionID
	private let webRTCConfig: WebRTCConfig

	internal var wrapped: WrapPeerConnectionWithDataChannel?

	private let negotiateSubject: PassthroughSubject<Void, Never> = .init()
	private let locallyICECandidateSubject: PassthroughSubject<WebRTCICECandidate, ConverseError> = .init()
	private let connectionStatusChangeSubject: PassthroughSubject<ConnectionStatusChangeEvent, ConverseError> = .init()
	private let incomingMessageSubject: PassthroughSubject<IncomingWebRTCMessage, ConverseError> = .init()

	public init(
		connectionID: P2PConnectionID,
		webRTCConfig: WebRTCConfig
	) throws {
		self.connectionID = connectionID
		self.webRTCConfig = webRTCConfig

		self.wrapped = try .init(
			connectionID: connectionID,
			webRTCConfig: webRTCConfig,
			peerConnectionDelegate: self,
			dataChannelDelegate: self
		)
	}
}

public extension WebRTCClient {
	var negotiatePublisher: AnyPublisher<Void, Never> {
		negotiateSubject.eraseToAnyPublisher()
	}

	var locallyICECandidatePublisher: AnyPublisher<WebRTCICECandidate, ConverseError> {
		locallyICECandidateSubject.eraseToAnyPublisher()
	}

	var incomingMessagePublisher: AnyPublisher<IncomingWebRTCMessage, ConverseError> {
		incomingMessageSubject.eraseToAnyPublisher()
	}

	var connectionStatusChangePublisher: AnyPublisher<ConnectionStatusChangeEvent, ConverseError> {
		connectionStatusChangeSubject.eraseToAnyPublisher()
	}

	func close() {
		wrapped?.close()
		wrapped = nil
	}

	func createOffer(callback: @escaping CreateOfferCallback) {
		guard let wrapped else {
			let error = ConverseError.WebRTC.wrappedPeerConnectionAndChannelIsNilProbablySinceCloseHasBeenCalled
			loggerGlobal.error("Failed to create offer, wrapped PeerConnectionAndChannel is nil (probably since 'close' was called on it.)")
			callback(.failure(error))
			return
		}
		wrapped.createOffer(callBack: callback)
	}
}

private extension WebRTCClient {
	func emit(
		connectionStatus: ConnectionStatus,
		source: ConnectionStatusChangeEvent.Source
	) {
		let changeEvent = ConnectionStatusChangeEvent(
			connectionID: connectionID,
			connectionStatus: connectionStatus,
			source: source
		)
		loggerGlobal.debug("Emitting connection status change event: \(changeEvent)")
		connectionStatusChangeSubject.send(changeEvent)
	}
}

public extension WebRTCClient {
	func sendData(_ data: Data) throws {
		guard let wrapped else {
			throw ConverseError.WebRTC.wrappedPeerConnectionAndChannelIsNilProbablySinceCloseHasBeenCalled
		}
		try wrapped.sendDataOverChannel(data)
	}
}

// MARK: WebRTCDataChannelDelegate
public extension WebRTCClient {
	var dataChannelLabelledID: DataChannelLabelledID {
		webRTCConfig.dataChannelConfig.dataChannelLabelledID
	}

	func dataChannel(
		labelledID: DataChannelLabelledID,
		didChangeReadyState dataChannelReadyState: DataChannelState
	) {
		loggerGlobal.debug("didChangeReadyState => \(dataChannelReadyState)")

		guard labelledID == self.dataChannelLabelledID else {
			let msg = "Received dataChannelEvent for wrong channel, self.dataChannelLabelledID=\(dataChannelLabelledID), but received event for: labelledID=\(labelledID)"
			loggerGlobal.warning(.init(stringLiteral: msg))
			assertionFailure(msg)
			return
		}
		let connectionStatus = ConnectionStatus(dataChannelState: dataChannelReadyState)
		emit(connectionStatus: connectionStatus, source: .dataChannelReadyState(channelID: labelledID, dataChannelReadyState: dataChannelReadyState))
	}

	func dataChannel(
		labelledID: DataChannelLabelledID,
		didReceiveMessageData messageData: Data
	) {
		guard labelledID == self.dataChannelLabelledID else {
			let msg = "Received dataChannelEvent for wrong channel, self.dataChannelLabelledID=\(dataChannelLabelledID), but received event for: labelledID=\(labelledID)"
			loggerGlobal.warning(.init(stringLiteral: msg))
			assertionFailure(msg)
			return
		}
		loggerGlobal.trace("Received msg of #\(messageData.count) bytes.")

		let receivedMessage = IncomingWebRTCMessage(
			message: messageData,
			connectionID: connectionID,
			dataChannelLabelledID: labelledID
		)

		incomingMessageSubject.send(receivedMessage)
	}
}

// MARK: WebRTCPeerConnectionDelegate

public extension WebRTCClient {
	func dataChannelReadyState() throws -> DataChannelState {
		guard let wrapped else {
			let error = ConverseError.WebRTC.wrappedPeerConnectionAndChannelIsNilProbablySinceCloseHasBeenCalled
			loggerGlobal.error("Failed to query DataChannel readyState, wrapped PeerConnectionAndChannel is nil (probably since 'close' was called on it.)")
			throw error
		}
		return try wrapped.dataChannelReadyState()
	}

	func peerConnection(
		id: P2PConnectionID,
		didChangeICEGatheringState iceGatheringState: ICEGatheringState
	) {
		loggerGlobal.debug("NOOP: didChangeICEGatheringState => \(iceGatheringState), id=\(id)")
	}

	func peerConnection(
		id: P2PConnectionID,
		didChangeSignalingState signalingState: SignalingState
	) {
		loggerGlobal.debug("NOOP: signalingState => \(signalingState), id=\(id)")
	}

	func peerConnectionShouldNegotiate(id: P2PConnectionID) {
		loggerGlobal.debug("peerConnectionShouldNegotiate, id=\(id)")
		negotiateSubject.send(())
	}

	func peerConnection(
		id: P2PConnectionID,
		didChangeICEConnectionState iceConnectionState: ICEConnectionState
	) {
		guard let connectionStatus = ConnectionStatus(iceConnectionState: iceConnectionState) else {
			loggerGlobal.debug("IGNORED iceConnectionState => \(iceConnectionState), id=\(id) because it deemed irreelvant,")
			return
		}
		emit(connectionStatus: connectionStatus, source: .iceConnection)
	}

	func peerConnection(
		id: P2PConnectionID,
		didGenerateICECandidate iceCandidate: WebRTCICECandidate
	) {
		guard id == self.connectionID else {
			let msg = "Received peerConnection event for wrong peerConnection, self.connectionID=\(connectionID), but received event for: id=\(id)"
			loggerGlobal.error(.init(stringLiteral: msg))
			assertionFailure(msg)
			return
		}

		locallyICECandidateSubject.send(iceCandidate)
	}

	func peerConnection(
		id: P2PConnectionID,
		didChangePeerConnectionState peerConnectionState: PeerConnectionState
	) {
		guard id == self.connectionID else {
			let msg = "Received peerConnection event for wrong peerConnection, self.connectionID=\(connectionID), but received event for: id=\(id)"
			loggerGlobal.error(.init(stringLiteral: msg))
			assertionFailure(msg)
			return
		}
		let connectionStatus = ConnectionStatus(peerConnectionState: peerConnectionState)
		emit(connectionStatus: connectionStatus, source: .peerConnection)
	}

	func peerConnection(
		id: P2PConnectionID,
		didRemoveICECandidates iceCandidates: [WebRTCICECandidate]
	) {
		loggerGlobal.debug("NOOP: didRemoveICECandidates, id=\(id)")
	}

	func peerConnection(
		id: P2PConnectionID,
		didAddStreamWithID streamID: String
	) {
		loggerGlobal.debug("NOOP: didAddStreamWithID, connection id=\(id)")
	}

	func peerConnection(
		id: P2PConnectionID,
		didRemoveStreamWithID streamID: String
	) {
		loggerGlobal.debug("NOOP: didRemoveStreamWithID, connection id=\(id)")
	}

	func peerConnection(
		id: P2PConnectionID,
		didOpenDataChannel labelledID: DataChannelLabelledID
	) {
		loggerGlobal.debug("NOOP: didOpenDataChannel, connection id=\(id)")
	}
}

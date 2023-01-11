import Foundation

// MARK: - ConverseError
public enum ConverseError: LocalizedError, Sendable {
	case connectError(ConnectError)
	case connectionsError(ConnectionsError)
	case unknownError(Swift.Error)
	case peer(PeerError)
	case chunkingTransport(ChunkingTransportError)
	case webRTC(WebRTC)
	case signalingServer(SignalingServer)
	case webSocket(WebSocket)
	case shared(Shared)
}

public extension ConverseError {
	var errorDescription: String? {
		switch self {
		case let .unknownError(error):
			return "Unknown error: \(String(describing: error))"
		case let .connectError(error):
			return "Connect error: \(String(describing: error))"
		case let .connectionsError(error):
			return "Connections error: \(String(describing: error))"
		case let .peer(error):
			return "P2PConnection error: \(String(describing: error))"
		case let .shared(error):
			return "Error: \(error.localizedDescription)"
		case let .webRTC(error):
			return "WebRTC error: \(error.localizedDescription)"
		case let .signalingServer(error):
			return "SignalingServerClient error: \(error.localizedDescription)"
		case let .webSocket(error):
			return "WebSocketClient error: \(error.localizedDescription)"
		case let .chunkingTransport(error):
			return "ChunkingTransport error: \(error.localizedDescription)"
		}
	}
}

public extension ConverseError {
	enum ConnectError: LocalizedError, Sendable {
		case failedToEstablishConnectionAfterMultipleAttempts(attempts: Int)
	}

	enum ConnectionsError: LocalizedError, Sendable {
		case noConnectionFoundForID(P2PConnectionID)
	}

	enum PeerError: String, LocalizedError, Sendable {
		case createdTransportWithNonMatchingConnectionIDs
		case unableToSendDataWebRTCClientIsNil
		case unableToSendReadReceiptWebRTCClientIsNil
	}

	enum Shared: String, LocalizedError, Sendable {
		case publisherFinishedWithoutValue
	}

	enum WebRTC: LocalizedError, Sendable {
		case peerWithIDAlreadyExists(P2PConnectionID)
		case failedToCreatePeerConnection(config: WebRTCPeerConnectionConfig)
		case failedToCreateDataChannel(config: WebRTCDataChannelConfig)

		case failedToBridgeRTCIceConnectionState(unknownCase: String)
		case failedToBridgeRTCDataChannelState(unknownCase: String)
		case failedToBridgeRTCIceGatheringState(unknownCase: String)
		case failedToBridgeRTCSignalingState(unknownCase: String)
		case failedToBridgeRTCPeerConnectionState(unknownCase: String)

		case failedToAddRemoteICECandidateSelfIsNil(connection: P2PConnectionID)
		case failedToAddRemoteICECandidate(underlyingError: Error)

		case failedToSetRemoteSDPDescriptionSelfIsNil(connection: P2PConnectionID)
		case failedToSetRemoteSDPDescription(underlyingError: Error)

		case failedToCreateOfferSelfIsNil(connection: P2PConnectionID)
		case failedToCreateOfferSDPIsNilAndSoIsError
		case failedToCreateOffer(underlyingError: Error)
		case failedToUpdatePeerConnectionWithOffer(underlyingError: Error)

		case failedToSetRemoteOfferSelfIsNil(connection: P2PConnectionID)
		case failedToSetRemoteAnswerSelfIsNil(connection: P2PConnectionID)

		case failedToSendDataSinceChannelIsNotOpen(DataChannelLabelledID)

		case wrappedPeerConnectionAndChannelIsNilProbablySinceCloseHasBeenCalled
	}

	enum WebSocket: LocalizedError, Sendable {
		case unableToPingTaskIsNil
		case unableToSendDataTaskIsNil
		case unableToReceiveTaskIsNil

		case pingFailed(underlyingError: Swift.Error)
		case sendDataFailed(underlyingError: Swift.Error)
		case receiveMessageFailed(underlyingError: Swift.Error)
	}

	enum SignalingServer: LocalizedError, Sendable {
		case failedToCreateSignalingServerURLInvalidPath
		case failedToCreateSignalingServerURLInvalidQueryParameters

		case unableToPingWebSocketClientIsNil
		case failedToPingSignalingServer(ConverseError.WebSocket)

		case unableToReceiveMessageWebSocketClientIsNil
		case unableToReceiveMessageSelfIsNil
		case failedToReceiveMessageReceivedUnexpectedMessageType(String)
		case failedToReceiveMessage(ConverseError.WebSocket)

		case failedToDisconnectSignalingServerSelfIsNil
		case failedToConnectToWebSocketSelfIsNil
		case failedToTransportRPCPrimitiveSelfIsNil
		case failedToExtractRPCFromIncomingMessageFromSignalingServerSelfIsNil
		case wrongConnectionSecretForEncryptedRPCMessage(rpcHasConnectionID: P2PConnectionID, connectionIDFromSecrets: P2PConnectionID)
		case failedToReceiveMessageDecodingError(Swift.Error)
		case failedToExtractRPCFromIncomingMessageFromSignalingServer(underlyingError: Swift.Error)
		case failedToTransportRPCPrimitiveFailedToPack(underlyingError: Swift.Error)
		case unableToTransportOutgoingMessageWebSocketClientIsNil
		case failedToTransportRPCMessageJSONEncodingFailed(underlyingError: Swift.Error)
		case failedToTransportRPCMessage(webSocketError: ConverseError.WebSocket)
	}

	enum ChunkingTransportError: LocalizedError, Sendable {
		case unknownError(Swift.Error)
		case assembler(AssemblerError)
		case receive(ReceiveError)
	}
}

public extension ConverseError.ChunkingTransportError {
	enum AssemblerError: LocalizedError, Sendable, Hashable {
		case foundReceiveMessageError(ChunkedMessageReceiveError)
		case parseError(ParseError)
		case messageByteCountMismatch(got: Int, butMetaDataPackageStated: Int)
		case hashMismatch(calculated: String, butExpected: String)
	}

	enum ReceiveError: LocalizedError, Sendable {
		case unknownError(Swift.Error)
		case alreadyGotMetaData(forMessageWithID: ChunkedMessagePackage.MessageID)
		case expectedFirstPackageToBeMetaDataPackage
		case failedToAssembleMessage(AssemblerError)
		case receivedMessageError(ChunkedMessageReceiveError)
		case invalidStateWhenReceivingPackage
	}
}

// MARK: - ConverseError.ChunkingTransportError.AssemblerError.ParseError
public extension ConverseError.ChunkingTransportError.AssemblerError {
	enum ParseError: LocalizedError, Sendable, Hashable {
		case noPackages
		case noMetaDataPackage
		case foundMultipleMetaDataPackages
		case metaDataPackageStatesZeroChunkPackages
		case invalidNumberOfChunkedPackages(got: Int, butMetaDataPackageStated: Int)

		/// E.g. if we only received chunked packages with indices of: `[1, 2, 3]` (instead of `[0, 1, 2]`).
		/// We do not throw this error if we receive chunked packages unordered, i.e. indices of `[1, 0, 2]` is
		/// allowed (however, inaccurate) because we can simple correct the order.
		case incorrectIndicesOfChunkedPackages
	}
}

public extension ConverseError.ChunkingTransportError {
	init(error: Swift.Error) {
		if let assemblerError = error as? AssemblerError {
			self = .assembler(assemblerError)
		} else if let parseError = error as? AssemblerError.ParseError {
			self = .assembler(.parseError(parseError))
		} else if let receiveError = error as? ReceiveError {
			self = .receive(receiveError)
		} else {
			self = .unknownError(error)
		}
	}
}

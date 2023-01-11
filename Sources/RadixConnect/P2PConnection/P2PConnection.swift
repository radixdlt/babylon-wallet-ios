import Combine
import P2PModels
import Prelude

// MARK: - P2PConnection
internal actor P2PConnection: Sendable, Hashable, Identifiable {
	internal nonisolated let config: P2PConfig

	private var cancellablesConnectingTransportAndSubjects: Set<AnyCancellable> = .init()

	private let connectionStatusAsyncBufferedChannel: AsyncThrowingBufferedChannel<ConnectionStatusChangeEvent, Swift.Error> = .init()
	private let connectionStatusAsyncReplaySubject: AsyncThrowingReplaySubject<ConnectionStatusChangeEvent, Swift.Error> = .init(bufferSize: 1)

	private let webSocketStatusAsyncBufferedChannel: AsyncBufferedChannel<WebSocketState> = .init()
	// Even though `webSocketStatusAsyncBufferedChannel` is not throwing due to internal limitations within
	// `AsyncExtension` package, the `multicast` operator requires the subject to be `Throwing`
	private let webSocketStatusAsyncReplaySubject: AsyncThrowingReplaySubject<WebSocketState, Swift.Error> = .init(bufferSize: 1)

	private let dataChannelStatusAsyncBufferedChannel: AsyncBufferedChannel<DataChannelState> = .init()
	// Even though `dataChannelStatusAsyncBufferedChannel` is not throwing due to internal limitations within
	// `AsyncExtension` package, the `multicast` operator requires the subject to be `Throwing`
	private let dataChannelStatusAsyncReplaySubject: AsyncThrowingReplaySubject<DataChannelState, Swift.Error> = .init(bufferSize: 1)

	private let incomingMessagesAsyncBufferedChannel: AsyncBufferedChannel<IncomingMessage> = .init()

	private let sentReceiptsAsyncBufferedChannel: AsyncBufferedChannel<SentReceipt> = .init()

	private var listenForReconnectTriggerTask: Task<Void, Error>?
	private var reconnectTask: Task<Void, Error>?

	private final class Transport {
		// Only place where we keep a strong references to `WebRTCClient`, it is the only purpose of this.
		private let webRTCClient: WebRTCClient
		fileprivate let chunkingTransport: ChunkingTransport
		private var cancellables = Set<AnyCancellable>()

		fileprivate init(
			webRTCClient: WebRTCClient,
			chunkingTransport: ChunkingTransport
		) throws {
			guard webRTCClient.connectionID == chunkingTransport.connectionID else {
				throw ConverseError.peer(.createdTransportWithNonMatchingConnectionIDs)
			}

			self.webRTCClient = webRTCClient
			self.chunkingTransport = chunkingTransport

			// Forward incoming message from `WebRTCClient` to `chunkingTransport` so these chunked messages
			// can be reassembled. Do NOT forget to ALSO forward reassembled messages from `chunkingTransport` back
			// to `self.incomingMessagesSubject` and DO NOT forget to ALSO forward confirmation on sent messages
			// back to `self.sentReceiptsSubject`
			webRTCClient.incomingMessagePublisher.sink(
				receiveCompletion: { [weak chunkingTransport] completion in
					loggerGlobal.warning("webRTCClient.incomingMessagePublisher completed with completion: \(String(describing: completion)) => forwarding completion to `chunkingTransport`")
					chunkingTransport?.webRTCClientIncomingMessage(completedWith: completion)
				},
				receiveValue: { [weak chunkingTransport, weak webRTCClient] receivedMessage in
					guard let webRTCClient else {
						loggerGlobal.warning("Received message when webRTCClient was nil")
						return
					}
					guard receivedMessage.connectionID == webRTCClient.connectionID else {
						loggerGlobal.critical("DISCREPANCY P2PConnection received message for the wrong connection ID, connection id of this P2PConnection is: \(webRTCClient.connectionID), got: \(String(describing: receivedMessage))")
						return
					}
					chunkingTransport?.receive(messageFromWebRTC: receivedMessage)
				}
			)
			.store(in: &cancellables)
		}

		func close() {
			cancellables.cancelAll()
			webRTCClient.close()
		}
	}

	private var transport: Transport?

	internal init(
		config: P2PConfig
	) {
		self.config = config
	}
}

// MARK: Public
internal extension P2PConnection {
	typealias SentReceipt = P2PConnections.SentReceipt
	typealias IncomingMessage = P2PConnections.IncomingMessage
	typealias MessageID = P2PConnections.MessageID

	nonisolated var id: P2PConnectionID { connectionID }
	nonisolated var connectionID: P2PConnectionID { config.connectionID }

	static func == (lhs: P2PConnection, rhs: P2PConnection) -> Bool {
		lhs.connectionID == rhs.connectionID
	}

	nonisolated func hash(into hasher: inout Hasher) {
		hasher.combine(connectionID)
	}
}

// MARK: Async Sequence
internal extension P2PConnection {
	/// A shared (multicast) async sequence.
	func incomingMessagesAsyncSequence() -> AnyAsyncSequence<IncomingMessage> {
		incomingMessagesAsyncBufferedChannel
			.share()
			.eraseToAnyAsyncSequence()
	}

	/// A shared (multicast) async sequence.
	func sentReceiptsAsyncSequence() -> AnyAsyncSequence<SentReceipt> {
		sentReceiptsAsyncBufferedChannel
			.share()
			.eraseToAnyAsyncSequence()
	}

	/// A replaying multicasting async sequence. We replay since it is strange that new subscribers should not
	/// be informed about the last connection status. This realization becomes apparent when writing UI, e.g. in
	/// Wallet's "ManageP2PClients" feature, if I add a new P2P connection I see the correct status "connected" in
	/// the list but if I dismiss the view and go into it again, the status is unknown since we have not emitted
	/// any update yet (we are still connected, but the view does not know about it).
	func connectionStatusAsyncSequence() -> AnyAsyncSequence<ConnectionStatusChangeEvent> {
		connectionStatusAsyncBufferedChannel
			// We want to replay, why we use `multicast` + ReplaySubject + autoconnect instead of `share` (which uses a PassthroughSubject)
			.multicast(connectionStatusAsyncReplaySubject)
			.autoconnect()
			.eraseToAnyAsyncSequence()
	}

	/// A replaying multicasting async sequence. We replay since it is strange that new subscribers should not
	/// be informed about the last connection status. This realization becomes apparent when writing UI, e.g. in
	/// Wallet's "ManageP2PClients" feature, if I add a new P2P connection I see the correct status "connected" in
	/// the list but if I dismiss the view and go into it again, the status is unknown since we have not emitted
	/// any update yet (we are still connected, but the view does not know about it).
	func dataChannelStatusAsyncSequence() -> AnyAsyncSequence<DataChannelState> {
		dataChannelStatusAsyncBufferedChannel
			// We want to replay, why we use `multicast` + ReplaySubject + autoconnect instead of `share` (which uses a PassthroughSubject)
			.multicast(dataChannelStatusAsyncReplaySubject)
			.autoconnect()
			.eraseToAnyAsyncSequence()
	}

	/// A replaying multicasting async sequence. We replay since it is strange that new subscribers should not
	/// be informed about the last connection status. This realization becomes apparent when writing UI, e.g. in
	/// Wallet's "ManageP2PClients" feature, if I add a new P2P connection I see the correct status "connected" in
	/// the list but if I dismiss the view and go into it again, the status is unknown since we have not emitted
	/// any update yet (we are still connected, but the view does not know about it).
	func webSocketStatusAsyncSequence() -> AnyAsyncSequence<WebSocketState> {
		webSocketStatusAsyncBufferedChannel
			// We want to replay, why we use `multicast` + ReplaySubject + autoconnect instead of `share` (which uses a PassthroughSubject)
			.multicast(webSocketStatusAsyncReplaySubject)
			.autoconnect()
			.eraseToAnyAsyncSequence()
	}
}

// MARK: Methods
internal extension P2PConnection {
	func disconnect() {
		listenForReconnectTriggerTask?.cancel()
		listenForReconnectTriggerTask = nil
		disconnectAndUnsubscribeFromConnectionStatusUpdates(cancelReconnectTask: true)
	}

	func connectWithRetries() async throws {
		try await connect(retryAttemptsLeft: config.connectorConfig.retryAttempts)
	}

	func connect(retryAttemptsLeft: Int, totalAttempts: Int = 0) async throws {
		guard retryAttemptsLeft >= 0 else {
			loggerGlobal.critical("Failed to establish connection even after #\(totalAttempts) attempts. Aborting.")
			throw ConverseError.connectError(.failedToEstablishConnectionAfterMultipleAttempts(attempts: totalAttempts))
		}
		do {
			try await connectAndSubscribeToConnectionStatusUpdates(cancelReconnectTask: true)

			// Setup reconnect
			loggerGlobal.debug("finished connecting, setting up reconnect")
			listenForReconnectTriggerTask = Task.detached(priority: .high) {
				for try await connectionStatusUpdateEvent in await self.connectionStatusAsyncSequence() {
					switch connectionStatusUpdateEvent.connectionStatus {
					case .failed, .closed, .disconnected:
						await self.reconnectIfNeeded(connectionStatusEventTriggeringReconnect: connectionStatusUpdateEvent)
					case .new, .closing, .connected, .connecting:
						loggerGlobal.trace("Ignored status, was not relevant for reconnect")
					}
				}
			}
		} catch {
			loggerGlobal.notice("Establish connection failed with error: \(String(describing: error)), will wait: \(config.connectorConfig.reconnectRetryDelay) seconds and then retry: #\(retryAttemptsLeft - 1) more times (have retried #\(totalAttempts) attempts already)")
			try? await Task.sleep(nanoseconds: UInt64(config.connectorConfig.reconnectRetryDelay * TimeInterval(NSEC_PER_SEC)))
			try await connect(retryAttemptsLeft: retryAttemptsLeft - 1, totalAttempts: totalAttempts + 1)
		}
	}

	func send(data: Data, id: String) async throws {
		try await sendDataUsingChunkingTransport(data: data, id: id)
	}

	func sendReadReceipt(
		for incomingMessage: IncomingMessage,
		alsoMarkMessageAsHandled: Bool = true
	) async throws {
		try await sendReadReceiptUsingChunkingTransport(
			for: incomingMessage,
			alsoMarkMessageAsHandled: alsoMarkMessageAsHandled
		)
	}
}

internal extension P2PConnection {
	func connectIfNeeded(force: Bool = false) async throws {
		if force {
			try await connectWithRetries()
		} else {
			guard transport == nil else { return }
			do {
				try await sendTestPigeon()
				return // seems to be connected
			} catch {
				try await connectWithRetries()
			}
		}
	}
}

// MAKR: Private
private extension P2PConnection {
	func sendTestPigeon() async throws {
		try await send(data: Data("Pigeon".utf8), id: UUID().uuidString)
	}

	func reconnectIfNeeded(connectionStatusEventTriggeringReconnect: ConnectionStatusChangeEvent) {
		guard reconnectTask == nil else {
			loggerGlobal.notice("Skipped reconnecting to peer since we a `reconnectTask` is present, i.e. we are probably already reconnecting. Triggered by: \(connectionStatusEventTriggeringReconnect)")
			return
		}
		loggerGlobal.notice("Reconnecting to peer, triggered by: \(connectionStatusEventTriggeringReconnect)")

		reconnectTask?.cancel()
		reconnectTask = Task {
			try await connectAndSubscribeToConnectionStatusUpdates(cancelReconnectTask: false)
		}
	}

	func disconnectAndUnsubscribeFromConnectionStatusUpdates(cancelReconnectTask: Bool) {
		loggerGlobal.notice("Disconnecting and cancelling subscriptions")
		if cancelReconnectTask {
			loggerGlobal.notice("Cancelling reconnect tasks and subscriptions.")
			reconnectTask?.cancel()
			reconnectTask = nil
		}
		transport?.close()
		transport = nil
		cancellablesConnectingTransportAndSubjects.cancelAll()

		connectionStatusAsyncBufferedChannel.send(.init(connectionID: connectionID, connectionStatus: .new, source: .user))
	}

	func connectAndSubscribeToConnectionStatusUpdates(
		cancelReconnectTask: Bool
	) async throws {
		defer {
			reconnectTask?.cancel()
			reconnectTask = nil
		}
		disconnectAndUnsubscribeFromConnectionStatusUpdates(
			cancelReconnectTask: cancelReconnectTask
		)
		connectionStatusAsyncBufferedChannel.send(.init(connectionID: connectionID, connectionStatus: .connecting, source: .user))

		loggerGlobal.notice("☑️ Establishing P2P Connection...")
		let webRTCClient = try await Self.establishConnection(
			config: config,
			appendWebSocketStateChangeUpdatesTo: self.webSocketStatusAsyncBufferedChannel,
			appendConnectionChangeUpdatesTo: self.connectionStatusAsyncBufferedChannel,
			appendDataChannelStateChangeUpdatesTo: self.dataChannelStatusAsyncBufferedChannel
		)
		loggerGlobal.notice("✅ Established P2P Connection, creating ChunkingTransport")

		let chunkingTransport = ChunkingTransport(
			connectionID: webRTCClient.connectionID,
			send: { [unowned webRTCClient] data in
				try webRTCClient.sendData(data)
			}
		)

		self.transport = try Transport(
			webRTCClient: webRTCClient,
			chunkingTransport: chunkingTransport
		)

		// Forward connection status from `WebRTCClient` to `self.connectionStatusSubject`,
		// and setup reconnect
		webRTCClient.connectionStatusChangePublisher.sink(
			receiveCompletion: { [weak self] completion in
				loggerGlobal.warning("webRTCClient.connectionStatusChangePublisher completed with completion: \(String(describing: completion)) => forwarding completion to `self?.connectionStatusSubject`")
				switch completion {
				case let .failure(error):
					self?.connectionStatusAsyncBufferedChannel.fail(error)
				case .finished:
					self?.connectionStatusAsyncBufferedChannel.finish()
				}
			},
			receiveValue: { [weak self] connectionStatusUpdateEvent in
				guard let self = self else {
					loggerGlobal.warning("P2PConnection received connectionStatusUpdateEvent from webRTCClient when Self is nil, statusEvent was: \(connectionStatusUpdateEvent)")
					return
				}
				guard connectionStatusUpdateEvent.connectionID == self.connectionID else {
					loggerGlobal.critical("DISCREPANCY P2PConnection received connectionStatusUpdateEvent for the wrong connection ID, connection id of this P2PConnection is: \(self.connectionID), got: \(String(describing: connectionStatusUpdateEvent))")
					return
				}

				switch connectionStatusUpdateEvent.source {
				case let .dataChannelReadyState(channelID, dataChannelReadyState):
					if channelID == self.config.webRTCConfig.dataChannelConfig.dataChannelLabelledID {
						self.dataChannelStatusAsyncBufferedChannel.send(dataChannelReadyState)
					} else {
						loggerGlobal.warning("Received update for non matching channel ID?")
					}
				default: break
				}

				loggerGlobal.debug("Emitting connection status update event: \(connectionStatusUpdateEvent)")
				self.connectionStatusAsyncBufferedChannel.send(connectionStatusUpdateEvent)
			}
		)
		.store(in: &cancellablesConnectingTransportAndSubjects)

		// Forward reassembled message from Chunking Transport to `incomingMessagesSubject`
		chunkingTransport.incomingMessagesPublisher.sink(
			receiveCompletion: { [weak self] completion in
				loggerGlobal.warning("chunkingTransport.incomingMessagesPublisher completed with completion: \(String(describing: completion)) => forwarding completion to `self?.incomingMessagesSubject`")
				self?.incomingMessagesAsyncBufferedChannel.finish()
			},
			receiveValue: { [weak self] reassembledMessage in
				guard let self = self else {
					loggerGlobal.warning("P2PConnection received and reassembled messages using chunking transport when Self is nil, message was: \(reassembledMessage)")
					return
				}
				self.incomingMessagesAsyncBufferedChannel.send(reassembledMessage)
			}
		)
		.store(in: &cancellablesConnectingTransportAndSubjects)

		// Forward read receipts from Chunking Transport to `sentReceiptsSubject`
		chunkingTransport.outgoingMessageConfirmedPublisher.sink(
			receiveCompletion: { [weak self] completion in
				loggerGlobal.warning("chunkingTransport.outgoingMessageConfirmedPublisher completed with completion: \(String(describing: completion)) => forwarding completion to `self?.sentReceiptsSubject`")
				self?.sentReceiptsAsyncBufferedChannel.finish()
			},
			receiveValue: { [weak self] sentReceipt in
				guard let self = self else {
					loggerGlobal.warning("P2PConnection received sent receipt for message using chunking transport when Self is nil, receipt was: \(sentReceipt)")
					return
				}
				self.sentReceiptsAsyncBufferedChannel.send(sentReceipt)
			}
		)
		.store(in: &cancellablesConnectingTransportAndSubjects)

		do {
			let dataChannelReadyState = try webRTCClient.dataChannelReadyState()
			dataChannelStatusAsyncBufferedChannel.send(dataChannelReadyState)
		} catch {}
	}

	func sendReadReceiptUsingChunkingTransport(
		for incomingMessage: IncomingMessage,
		alsoMarkMessageAsHandled: Bool = true
	) async throws {
		guard let transport else {
			loggerGlobal.error("Unable to send read receipt, WebRTCClient is nil.")
			throw ConverseError.peer(.unableToSendReadReceiptWebRTCClientIsNil)
		}
		try transport.chunkingTransport.sendReceiveMessageConfirmation(for: incomingMessage, markMessageAsHandled: alsoMarkMessageAsHandled)
	}

	func sendDataUsingChunkingTransport(data: Data, id: String) async throws {
		guard let transport else {
			loggerGlobal.error("Unable to send data, WebRTCClient is nil.")
			self.connectionStatusAsyncBufferedChannel.send(
				.init(
					connectionID: self.connectionID,
					connectionStatus: .failed,
					source: .dataChannelReadyState(
						channelID: self.config.webRTCConfig.dataChannelConfig.dataChannelLabelledID,
						dataChannelReadyState: .closed
					)
				)
			)
			throw ConverseError.peer(.unableToSendDataWebRTCClientIsNil)
		}
		try transport.chunkingTransport.send(data: data, messageID: id)
	}
}

// MAKR: Private Static
private extension P2PConnection {
	static func establishConnection(
		config: P2PConfig,
		appendWebSocketStateChangeUpdatesTo: AsyncBufferedChannel<WebSocketState>,
		appendConnectionChangeUpdatesTo connectionStatusAsyncChannel: AsyncThrowingBufferedChannel<ConnectionStatusChangeEvent, Swift.Error>,
		appendDataChannelStateChangeUpdatesTo: AsyncBufferedChannel<DataChannelState>
	) async throws -> WebRTCClient {
		loggerGlobal.info("☑️ 🔌 Establishing P2P Connection, connectionID: \(config.connectionID)...")
		let signalingServer = try SignalingServerClient(
			config: config.signalingServerConfig,
			connectionSecrets: config.connectionSecrets
		)
		loggerGlobal.debug("Created Signaling Server")
		let webRTCClient = try WebRTCClient(
			connectionID: config.connectionID,
			webRTCConfig: config.webRTCConfig
		)
		loggerGlobal.debug("Created webRTCClient")
		var cancellables = Set<AnyCancellable>()
		defer {
			cancellables.cancelAll()
		}
		let negotiateSubject = PassthroughSubject<Void, Never>()
		let isConnectedSubject = CurrentValueSubject<Result<Bool, ConverseError>, Never>(.success(false))

		signalingServer.webSocketStatePublisher.sink(receiveValue: { state in
			appendWebSocketStateChangeUpdatesTo.send(state)
		}).store(in: &cancellables)

		webRTCClient.connectionStatusChangePublisher.sink(
			receiveCompletion: { completion in
				loggerGlobal.warning("webRTCClient.connectionStatusChangePublisher completed with completion: \(String(describing: completion)) => forwarding completion to `publishConnectionChangeUpdatesOn`")
				switch completion {
				case let .failure(error):
					connectionStatusAsyncChannel.fail(error)
				case .finished:
					connectionStatusAsyncChannel.finish()
				}
			},
			receiveValue: { connectionStatusChangeEvent in
				loggerGlobal.info("[⚪️, 🔵, 🟢] Connection status change event: \(connectionStatusChangeEvent)")
				connectionStatusAsyncChannel.send(connectionStatusChangeEvent)

				switch connectionStatusChangeEvent.source {
				case let .dataChannelReadyState(channelID, dataChannelReadyState):
					if channelID == config.webRTCConfig.dataChannelConfig.dataChannelLabelledID {
						appendDataChannelStateChangeUpdatesTo.send(dataChannelReadyState)
					} else {
						loggerGlobal.warning("Received update for non matching channel ID?")
					}
				default: break
				}

				switch connectionStatusChangeEvent.connectionStatus {
				case .connected:
					isConnectedSubject.send(.success(true))
				default:
					isConnectedSubject.send(.success(false))
				}
			}
		).store(in: &cancellables)

		webRTCClient.locallyICECandidatePublisher
			.skipError(logPrefix: "Local ICE Candidate publisher")
			.flatMap { (candidate: WebRTCICECandidate) -> AnyPublisher<Void, Never> in
				loggerGlobal.debug("❄️ Discovered a ICE candidate")
				loggerGlobal.debug("❄️ Sending the ICE candidate...")
				defer { loggerGlobal.debug("❄️ Sent ICE candiate") }
				return signalingServer
					.sendingICECandidate(candidate)
					.skipError(logPrefix: "Send ICE Candidate")
			}
			.sink(receiveValue: {
				loggerGlobal.info("❄️ Discovered and sent local ICECandidate to remote via signaling server")
			})
			.store(in: &cancellables)

		signalingServer.iceCandidateFromRemoteClientPublisher
			.skipError(logPrefix: "ICE Candidate from remote publisher")
			.flatMap {
				loggerGlobal.debug("❄️ Received remote ICE candidate")
				loggerGlobal.debug("❄️ Updating WebRTC with ICE candidate...")
				defer { loggerGlobal.debug("❄️ Updated WebRTC with ICE candidate...") }
				return webRTCClient
					.settingRemoteICECandidate($0)
					.skipError(logPrefix: "Setting ICE Candidate from remote publisher")
			}
			.sink(receiveValue: {
				loggerGlobal.info("❄️ Received ICECandidates from remote via signaling server, finished updating WebRTC with them")
			})
			.store(in: &cancellables)

		Publishers.Merge(
			webRTCClient.negotiatePublisher,
			negotiateSubject
		)
		.flatMap {
			loggerGlobal.debug("Negotiation started!")
			return webRTCClient
				.creatingOffer()
				.skipError(
					logPrefix: "Create Offer",
					onError: { isConnectedSubject.send(.failure($0)) }
				)
		}
		.flatMap {
			loggerGlobal.info("📡⬆️🤜 Created offer")
			loggerGlobal.debug("📡⬆️🤜 Sending offer...")
			defer { loggerGlobal.info("📡⬆️🤜 Sent offer") }
			return signalingServer
				.sendingOffer($0)
				.skipError(
					logPrefix: "Send Offer",
					onError: { isConnectedSubject.send(.failure($0)) }
				)
		}
		.flatMap {
			loggerGlobal.debug("📡⬇️🤛 Waiting for answer from remote...")
			defer { loggerGlobal.info("📡⬇️🤛 Got answer from remote") }
			return signalingServer
				.answerFromRemoteClientPublisher
				.skipError(
					logPrefix: "Get Answer from remote",
					onError: { isConnectedSubject.send(.failure($0)) }
				)
		}
		.flatMap {
			loggerGlobal.info("⬇️🤛 Updating WebRTC with answer...")
			defer { loggerGlobal.info("⬇️🤛 Updated WebRTC with answer") }
			return webRTCClient
				.settingRemoteAnswer($0)
				.skipError(
					logPrefix: "Setting Answer from remote",
					onError: { isConnectedSubject.send(.failure($0)) }
				)
		}
		.sink(
			receiveValue: { _ in
				loggerGlobal.info("Finished with negotiation")
			})
		.store(in: &cancellables)

		loggerGlobal.debug("📡⚪️ Connecting to signaling server...")
		try await signalingServer.connect()
		loggerGlobal.info("📡🟢 Connected to signaling server")

		loggerGlobal.debug("Waiting for remote client to connect to signaling server...")
		signalingServer.remoteClientIsAlreadyConnectedOrJustConnectedPublisher
			.skipError(
				logPrefix: "Waiting for remote client to connect to Signal Server",
				onError: { isConnectedSubject.send(.failure($0)) }
			)
			.sink(
				receiveValue: {
					loggerGlobal.notice("Remote client just connected => Triggering negotation")
					negotiateSubject.send()
				}).store(in: &cancellables)

		loopLabel: for await connectionStatusUpdate in isConnectedSubject.values {
			switch connectionStatusUpdate {
			case .success(true):
				cancellables.cancelAll()
				loggerGlobal.debug("CONNECTED! breaking out of switch")
				break loopLabel
			case .success(false):
				loggerGlobal.debug("Not connected yet, continue")
				continue
			case let .failure(error):
				loggerGlobal.error("Failure during connection flow, throwing error: \(error)")
				throw error
			}
		}
		// WebRTC is now connected
		loggerGlobal.debug("WebRTC connection flow established connection with remote peer => cancelling cancellables")
		loggerGlobal.debug("Disconnecting from signaling server...")
		try await signalingServer.disconnect()
		loggerGlobal.info("📡🔴 Disconnected from signaling server.")

		return webRTCClient
	}
}

public extension Set where Element == AnyCancellable {
	mutating func cancelAll() {
		forEach { $0.cancel() }
		removeAll()
	}
}

extension Publisher where Failure == ConverseError {
	func skipError(
		logPrefix prefix: String,
		onError: ((ConverseError) -> Void)? = nil
	) -> AnyPublisher<Output, Never> {
		self.map { (output: Output) -> Output? in
			Output?.some(output)
		}
		.catch { error in
			onError?(error)
			loggerGlobal.error("\(prefix) error: \(String(describing: error))")
			return Just<Output?>(nil)
		}
		.compactMap { $0 } // filter nil
		.eraseToAnyPublisher()
	}
}

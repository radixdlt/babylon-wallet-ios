import Combine
import P2PModels
import Prelude

// MARK: - P2PConnections
/// Entry point for managing P2P Connections, this GlobalActor are the only
/// holder of strong references to `P2PConnection` actors. Instead of reaching
/// into the underlying async sequences for incoming messages, sent receipts and
/// connection status on each individual P2PConnection, this coordinating actor
/// provides async sequences by `P2PConnectionID` (==` P2PClient.ID`).
public actor P2PConnections: GlobalActor {
	public typealias IDs = OrderedSet<P2PConnectionID>
	private var connections: OrderedSet<P2PConnection>

	private let connectionsUpdatesAsyncBufferedChannel: AsyncBufferedChannel<IDs> = .init()

	private init() {
		connections = .init()
	}

	public static let shared = P2PConnections()
}

// MARK: CRUD
extension P2PConnections {
	public typealias SentReceipt = ChunkingTransport.SentReceipt
	public typealias IncomingMessage = ChunkingTransport.IncomingMessage
	public typealias MessageID = IncomingMessage.MessageID

	/// throws an error if no connection with the given ID is found, use `add` methods
	/// if this is a new connection.
	public func connect(id: ID, force: Bool) async throws {
		guard let connection = self.get(id: id) else {
			throw ConverseError.connectionsError(.noConnectionFoundForID(id))
		}
		try await connect(connection, force: force)
	}

	/// returns `P2PConnectionID` of new or aleady existing `P2PConnection`
	public func add(
		config: P2PConfig,
		connectMode: ConnectMode,
		emitConnectionsUpdate shouldEmitConnectionsUpdate: Bool = true
	) async throws -> ID {
		try await doAdd(
			config: config,
			emitConnectionsUpdate: shouldEmitConnectionsUpdate,
			mode: connectMode
		)
	}

	/// returns `true` iff the connection was present (and removed), returns `false` if the connection was not present.
	@discardableResult
	public func removeAndDisconnect(id: ID) async throws -> Bool {
		try await doRemoveAndDisconnect(id: id, emitConnectionsUpdate: true)
	}

	public func removeAndDisconnectAll() async throws {
		defer { emitConnectionsUpdate() }
		try await withThrowingTaskGroup(of: Void.self) { [unowned self] group in
			for connection in self.connections {
				_ = group.addTaskUnlessCancelled { [weak self, unowned connection] in
					try await self?.doRemoveAndDisconnect(
						connection: connection,
						emitConnectionsUpdate: false
					)
				}
			}
			try await group.waitForAll()
		}
	}

	/// returns `true` iff all connections were added, returns `false` if any of the connection already existed
	public func add(
		connectionsFor configs: OrderedSet<P2PConfig>,
		connectMode: ConnectMode,
		emitConnectionsUpdate shouldEmitConnectionsUpdate: Bool = true
	) async throws {
		defer {
			if shouldEmitConnectionsUpdate {
				emitConnectionsUpdate()
			}
		}
		try await withThrowingTaskGroup(of: Void.self) { group in
			for config in configs {
				_ = group.addTaskUnlessCancelled { [weak self, config] in
					_ = try await self?.doAdd(
						config: config,
						emitConnectionsUpdate: false,
						mode: connectMode
					)
				}
			}
			try await group.waitForAll()
		}
	}

	/// returns `true` iff all connections were added, returns `false` if any of the connection already existed
	public func add(
		connectionsFor clients: OrderedSet<P2PClient>,
		connectMode: ConnectMode = .connect(force: false, inBackground: false),
		emitConnectionsUpdate shouldEmitConnectionsUpdate: Bool = true
	) async throws {
		try await add(
			connectionsFor: .init(clients.map(\.config)),
			connectMode: connectMode,
			emitConnectionsUpdate: shouldEmitConnectionsUpdate
		)
	}

	/// returns `true` iff all connections were added, returns `false` if any of the connection already existed
	public func add(
		connectionsFor clients: P2PClients,
		connectMode: ConnectMode = .connect(force: false, inBackground: false),
		emitConnectionsUpdate shouldEmitConnectionsUpdate: Bool = true
	) async throws {
		try await add(
			connectionsFor: clients.clients,
			connectMode: connectMode,
			emitConnectionsUpdate: shouldEmitConnectionsUpdate
		)
	}
}

// MARK: API
extension P2PConnections {
	public typealias ID = P2PConnectionID

	/// A non replaying non multicasted async sequence
	public func connectionIDsAsyncSequence() async throws -> AnyAsyncSequence<IDs> {
		connectionsUpdatesAsyncBufferedChannel.eraseToAnyAsyncSequence()
	}

	/// A shared (multicast) async sequence.
	public func sentReceiptsAsyncSequence(
		for id: ID
	) async throws -> AnyAsyncSequence<SentReceipt> {
		try await asyncSequence(for: id) { await $0.sentReceiptsAsyncSequence() }
	}

	/// A replaying multicasting async sequence.
	public func connectionStatusChangeEventAsyncSequence(
		for id: ID
	) async throws -> AnyAsyncSequence<ConnectionStatusChangeEvent> {
		try await asyncSequence(for: id) { await $0.connectionStatusAsyncSequence() }
	}

	/// A shared (multicast) async sequence.
	public func incomingMessagesAsyncSequence(
		for id: ID
	) async throws -> AnyAsyncSequence<IncomingMessage> {
		try await asyncSequence(for: id) { await $0.incomingMessagesAsyncSequence() }
	}

	/// Sends a message recived confirmation (receipt) for `readMessage` back to
	/// sending remote peer over WebRTC.
	public func sendReceipt(
		for id: ID,
		readMessage: IncomingMessage,
		alsoMarkMessageAsHandled: Bool = true
	) async throws {
		guard let connection = self.get(id: id) else {
			return
		}
		try await connection.sendReadReceipt(for: readMessage, alsoMarkMessageAsHandled: alsoMarkMessageAsHandled)
	}

	/// Sends `data` to remote peer over WebRTC.
	public func sendData(for id: ID, data: Data, messageID: String) async throws {
		guard let connection = self.get(id: id) else {
			return
		}
		try await connection.send(data: data, id: messageID)
	}
}

// MARK: Convenience
extension P2PConnections {
	/// Just sugar for `add(config:autoconnect)` applying default configs.
	/// returns `P2PConnectionID` of new or already existing `P2PConnection`
	public func add(
		connectionPassword: ConnectionPassword,
		connectMode: ConnectMode = .connect(force: false, inBackground: false),
		emitConnectionsUpdate shouldEmitConnectionsUpdate: Bool = true
	) async throws -> ID {
		try await add(
			config: .init(connectionPassword: connectionPassword),
			connectMode: connectMode,
			emitConnectionsUpdate: shouldEmitConnectionsUpdate
		)
	}
}

// MARK: Debug
extension P2PConnections {
	/// A replaying multicasting async sequence.
	public func debugDataChannelState(
		for id: ID
	) async throws -> AnyAsyncSequence<DataChannelState> {
		try await asyncSequence(for: id) { await $0.dataChannelStatusAsyncSequence() }
	}

	/// A replaying multicasting async sequence.
	public func debugWebSocketState(
		for id: ID
	) async throws -> AnyAsyncSequence<WebSocketState> {
		try await asyncSequence(for: id) { await $0.webSocketStatusAsyncSequence() }
	}
}

// MARK: - ConnectMode
public enum ConnectMode: Sendable, Hashable {
	case skipConnecting
	case connect(force: Bool, inBackground: Bool)
}

// MARK: Private
extension P2PConnections {
	private func emitConnectionsUpdate() {
		connectionsUpdatesAsyncBufferedChannel.send(
			OrderedSet(connections.map(\.connectionID))
		)
	}

	/// returns `P2PConnectionID` of new or already existing `P2PConnection`
	private func doAdd(
		config: P2PConfig,
		emitConnectionsUpdate shouldEmitConnectionsUpdate: Bool,
		mode: ConnectMode
	) async throws -> ID {
		defer {
			if shouldEmitConnectionsUpdate {
				emitConnectionsUpdate()
			}
		}
		let connection = {
			if let existing = get(id: config.connectionID) {
				return existing
			} else {
				let new = P2PConnection(config: config)
				connections.append(new)
				return new
			}
		}()

		switch mode {
		case let .connect(force, inBackground):
			if inBackground {
				Task {
					try await connect(connection, force: force)
				}
			} else {
				try await connect(connection, force: force)
			}
		case .skipConnecting: break
		}

		return connection.id
	}

	fileprivate func connect(_ connection: P2PConnection, force: Bool) async throws {
		try await connection.connectIfNeeded(force: force)
	}

	/// returns `true` iff the connection was present (and removed), returns `false` if the connection was not present.
	@discardableResult
	private func doRemoveAndDisconnect(
		id: ID,
		emitConnectionsUpdate shouldEmitConnectionsUpdate: Bool
	) async throws -> Bool {
		guard let connection = get(id: id) else { return false }

		try await doRemoveAndDisconnect(
			connection: connection,
			emitConnectionsUpdate: shouldEmitConnectionsUpdate
		)
		return true
	}

	private func get(id: ID) -> P2PConnection? {
		connections.first(where: { $0.connectionID == id })
	}

	/// returns `true` iff the connection was present (and removed), returns `false` if the connection was not present.
	private func doRemoveAndDisconnect(
		connection: P2PConnection,
		emitConnectionsUpdate shouldEmitConnectionsUpdate: Bool
	) async throws {
		connections.remove(connection)
		await connection.disconnect()
		if shouldEmitConnectionsUpdate {
			emitConnectionsUpdate()
		}
	}

	private func asyncSequence<Element>(
		for id: ID,
		from: (P2PConnection) async -> AnyAsyncSequence<Element>
	) async throws -> AnyAsyncSequence<Element> {
		guard let connection = self.get(id: id) else {
			throw ConverseError.connectionsError(.noConnectionFoundForID(id))
		}
		return await from(connection)
	}
}

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
public extension P2PConnections {
	typealias SentReceipt = ChunkingTransport.SentReceipt
	typealias IncomingMessage = ChunkingTransport.IncomingMessage
	typealias MessageID = IncomingMessage.MessageID

	/// throws an error if no connection with the given ID is found, use `add` methods
	/// if this is a new connection.
	func connect(id: ID, force: Bool) async throws {
		guard let connection = self.get(id: id) else {
			throw ConverseError.connectionsError(.noConnectionFoundForID(id))
		}
		try await connect(connection, force: force)
	}

	/// returns `P2PConnectionID` of new or aleady existing `P2PConnection`
	func add(
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
	func removeAndDisconnect(id: ID) async throws -> Bool {
		try await doRemoveAndDisconnect(id: id, emitConnectionsUpdate: true)
	}

	func removeAndDisconnectAll() async throws {
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
	func add(
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
	func add(
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
	func add(
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
public extension P2PConnections {
	typealias ID = P2PConnectionID

	/// A non replaying non multicasted async sequence
	func connectionIDsAsyncSequence() async throws -> AnyAsyncSequence<IDs> {
		connectionsUpdatesAsyncBufferedChannel.eraseToAnyAsyncSequence()
	}

	/// A shared (multicast) async sequence.
	func sentReceiptsAsyncSequence(
		for id: ID
	) async throws -> AnyAsyncSequence<SentReceipt> {
		try await asyncSequence(for: id) { await $0.sentReceiptsAsyncSequence() }
	}

	/// A replaying multicasting async sequence.
	func connectionStatusChangeEventAsyncSequence(
		for id: ID
	) async throws -> AnyAsyncSequence<ConnectionStatusChangeEvent> {
		try await asyncSequence(for: id) { await $0.connectionStatusAsyncSequence() }
	}

	/// A shared (multicast) async sequence.
	func incomingMessagesAsyncSequence(
		for id: ID
	) async throws -> AnyAsyncSequence<IncomingMessage> {
		try await asyncSequence(for: id) { await $0.incomingMessagesAsyncSequence() }
	}

	/// Sends a message recived confirmation (receipt) for `readMessage` back to
	/// sending remote peer over WebRTC.
	func sendReceipt(
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
	func sendData(for id: ID, data: Data, messageID: String) async throws {
		guard let connection = self.get(id: id) else {
			return
		}
		try await connection.send(data: data, id: messageID)
	}
}

// MARK: Convenience
public extension P2PConnections {
	/// Just sugar for `add(config:autoconnect)` applying default configs.
	/// returns `P2PConnectionID` of new or already existing `P2PConnection`
	func add(
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
public extension P2PConnections {
	/// A replaying multicasting async sequence.
	func debugDataChannelState(
		for id: ID
	) async throws -> AnyAsyncSequence<DataChannelState> {
		try await asyncSequence(for: id) { await $0.dataChannelStatusAsyncSequence() }
	}

	/// A replaying multicasting async sequence.
	func debugWebSocketState(
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
private extension P2PConnections {
	func emitConnectionsUpdate() {
		connectionsUpdatesAsyncBufferedChannel.send(
			OrderedSet(connections.map(\.connectionID))
		)
	}

	/// returns `P2PConnectionID` of new or already existing `P2PConnection`
	func doAdd(
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

	func connect(_ connection: P2PConnection, force: Bool) async throws {
		try await connection.connectIfNeeded(force: force)
	}

	/// returns `true` iff the connection was present (and removed), returns `false` if the connection was not present.
	@discardableResult
	func doRemoveAndDisconnect(
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

	func get(id: ID) -> P2PConnection? {
		connections.first(where: { $0.connectionID == id })
	}

	/// returns `true` iff the connection was present (and removed), returns `false` if the connection was not present.
	func doRemoveAndDisconnect(
		connection: P2PConnection,
		emitConnectionsUpdate shouldEmitConnectionsUpdate: Bool
	) async throws {
		connections.remove(connection)
		await connection.disconnect()
		if shouldEmitConnectionsUpdate {
			emitConnectionsUpdate()
		}
	}

	func asyncSequence<Element>(
		for id: ID,
		from: (P2PConnection) async -> AnyAsyncSequence<Element>
	) async throws -> AnyAsyncSequence<Element> {
		guard let connection = self.get(id: id) else {
			throw ConverseError.connectionsError(.noConnectionFoundForID(id))
		}
		return await from(connection)
	}
}

import AsyncExtensions
import ChunkingTransport
import ComposableArchitecture
import Converse
import ConverseCommon
import Foundation
import Profile
import ProfileClient

// MARK: - BrowserExtensionWithConnectionStatus
public struct BrowserExtensionWithConnectionStatus: Identifiable, Equatable {
	public let browserExtensionConnection: BrowserExtensionConnection
	public var connectionStatus: Connection.State

	public init(
		browserExtensionConnection: BrowserExtensionConnection,
		connectionStatus: Connection.State = .disconnected
	) {
		self.browserExtensionConnection = browserExtensionConnection
		self.connectionStatus = connectionStatus
	}
}

public extension BrowserExtensionWithConnectionStatus {
	typealias ID = BrowserExtensionConnection.ID
	var id: ID { browserExtensionConnection.id }
}

// MARK: - BrowserExtensionsConnectivityClient+TestValue
public extension BrowserExtensionsConnectivityClient {
	#if DEBUG
	static let testValue = Self.mock()
	static func mock() -> Self {
		Self(
			getBrowserExtensionConnections: { [] },
			addBrowserExtensionConnection: { _ in },
			deleteBrowserExtensionConnection: { _ in },
			getConnectionStatusAsyncSequence: { _ in AsyncLazySequence([]).eraseToAnyAsyncSequence() },
			getIncomingMessageAsyncSequence: { _ in AsyncLazySequence([]).eraseToAnyAsyncSequence() },
			sendMessage: { _, _ in }
		)
	}
	#endif // DEBUG
}

public extension DependencyValues {
	var browserExtensionsConnectivityClient: BrowserExtensionsConnectivityClient {
		get { self[BrowserExtensionsConnectivityClient.self] }
		set { self[BrowserExtensionsConnectivityClient.self] = newValue }
	}
}

// MARK: - BrowserExtensionsConnectivityClient

//  MARK: - BrowerExtensionsConnectivity
public struct BrowserExtensionsConnectivityClient: DependencyKey {
	public var getBrowserExtensionConnections: GetBrowserExtensionConnections
	public var addBrowserExtensionConnection: AddBrowserExtensionConnection
	public var deleteBrowserExtensionConnection: DeleteBrowserExtensionConnection

	public var getConnectionStatusAsyncSequence: GetConnectionStatusAsyncSequence
	public var getIncomingMessageAsyncSequence: GetIncomingMessageAsyncSequence
	public var sendMessage: SendMessage
}

public extension BrowserExtensionsConnectivityClient {
	typealias GetBrowserExtensionConnections = @Sendable () throws -> [BrowserExtensionWithConnectionStatus]
	typealias AddBrowserExtensionConnection = @Sendable (BrowserExtensionConnection) async throws -> Void
	typealias DeleteBrowserExtensionConnection = @Sendable (BrowserExtensionConnection.ID) async throws -> Void

	typealias GetConnectionStatusAsyncSequence = @Sendable (BrowserExtensionConnection.ID) throws -> AnyAsyncSequence<BrowserConnectionUpdate>
	typealias GetIncomingMessageAsyncSequence = @Sendable (BrowserExtensionConnection.ID) async throws -> AnyAsyncSequence<ChunkingTransport.IncomingMessage> // FIXME: change to `IncomingMessageFromBrowser`
	typealias SendMessage = @Sendable (BrowserExtensionConnection.ID, String) async throws -> Void
}

// MARK: - StatefulBrowserConnection
private struct StatefulBrowserConnection {
	public let browserExtensionConnection: BrowserExtensionConnection
	public var connection: Connection
}

// MARK: - NoConnectionMatchingIDFound
struct NoConnectionMatchingIDFound: Swift.Error {}
public extension BrowserExtensionsConnectivityClient {
	static let liveValue: Self = {
		@Dependency(\.profileClient) var profileClient

		final class ConnectionsHolder {
			private var connections: [ConnectionID: StatefulBrowserConnection] = [:]
			static let shared = ConnectionsHolder()
			func mapID(_ passwordID: BrowserExtensionConnection.ID) throws -> ConnectionID {
				let connectionPassword = try ConnectionPassword(data: Data(hexString: passwordID))
				return try ConnectionID(password: connectionPassword)
			}

			func addConnection(_ connection: StatefulBrowserConnection) {
				let key = connection.connection.getConnectionID()
				guard connections[key] == nil else {
					return
				}
				self.connections[key] = connection
				Task.detached {
					try await connection.connection.establish()
				}
			}

			func getConnection(id: BrowserExtensionConnection.ID) throws -> StatefulBrowserConnection {
				let key = try mapID(id)
				guard let connection = connections[key] else {
					throw NoConnectionMatchingIDFound()
				}
				return connection
			}
		}

		let connectionsHolder = ConnectionsHolder.shared

		return Self(
			getBrowserExtensionConnections: {
				let connections = try profileClient.getBrowserExtensionConnections()
				return try connections.connections.map { browserConnection in

					let password = try ConnectionPassword(data: browserConnection.connectionPassword.data)
					let secrets = try ConnectionSecrets.from(connectionPassword: password)
					let connection = Connection.live(connectionSecrets: secrets)

					let statefulConnection = StatefulBrowserConnection(
						browserExtensionConnection: browserConnection,
						connection: connection
					)

					connectionsHolder.addConnection(statefulConnection)

					return BrowserExtensionWithConnectionStatus(
						browserExtensionConnection: browserConnection
					)
				}

			},
			addBrowserExtensionConnection: { browserConnection in
				try await profileClient.addBrowserExtensionConnection(browserConnection)
			},
			deleteBrowserExtensionConnection: { id in
				try await profileClient.deleteBrowserExtensionConnection(id)
			},
			getConnectionStatusAsyncSequence: { id in
				let connection = try connectionsHolder.getConnection(id: id)
				return connection.connection.connectionStatus().map { newStatus in
					BrowserConnectionUpdate(connectionStatus: newStatus, browserExtensionConnection: connection.browserExtensionConnection)
				}.eraseToAnyAsyncSequence()
			},
			getIncomingMessageAsyncSequence: { id in
				let connection = try connectionsHolder.getConnection(id: id)
				return await connection.connection.receive()
			},
			sendMessage: { id, message in
				let connection = try connectionsHolder.getConnection(id: id)
				let outgoingMessage = Connection.OutgoingMessage(
					data: Data(message.utf8),
					id: UUID().uuidString
				)

				try await connection.connection.send(outgoingMessage)
			}
		)
	}()
}

// MARK: - IncomingMessageFromBrowser
public struct IncomingMessageFromBrowser: Sendable, Equatable {
	public let requestMethodWalletRequest: RequestMethodWalletRequest
	public let browserExtensionConnection: BrowserExtensionConnection
}

// MARK: - BrowserConnectionUpdate
public struct BrowserConnectionUpdate: Sendable, Equatable {
	public let connectionStatus: Connection.State
	public let browserExtensionConnection: BrowserExtensionConnection
}

// MARK: - Connection.State + Sendable
// FIXME: Make `Connection.State` sendable in `Converse`
extension Connection.State: @unchecked Sendable {}

import ComposableArchitecture
import Converse
import ConverseCommon
import Foundation
import Profile
import ProfileClient

// MARK: - BrowserExtensionConnectionWithState
public struct BrowserExtensionConnectionWithState: Identifiable, Equatable {
	public let browserExtensionConnection: BrowserExtensionConnection
	public var connectionStatus: Connection.State

	public init(
		browserExtensionConnection: BrowserExtensionConnection,
		//        statefulConnection: Connection,
		connectionStatus: Connection.State = .disconnected
	) {
		self.browserExtensionConnection = browserExtensionConnection
		//        self.statefulConnection = statefulConnection
		self.connectionStatus = connectionStatus
	}
}

public extension BrowserExtensionConnectionWithState {
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
			deleteBrowserExtensionConnection: { _ in }
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

	//    public var addBrowserConnectionUpdateListener: AddBrowserConnectionUpdateListener
	//    public var addIncomingMessageFromBrowserListener: AddIncomingMessageFromBrowserListener
}

public extension BrowserExtensionsConnectivityClient {
	typealias GetBrowserExtensionConnections = @Sendable () throws -> [BrowserExtensionConnectionWithState]
	typealias AddBrowserExtensionConnection = @Sendable (BrowserExtensionConnection) async throws -> Void
	typealias DeleteBrowserExtensionConnection = @Sendable (BrowserExtensionConnection.ID) async throws -> Void

	//    typealias BrowserConnectionUpdateListener = @Sendable (BrowserConnectionUpdate) -> Void
	//    typealias AddBrowserConnectionUpdateListener = @Sendable (BrowserExtensionConnection.ID, BrowserConnectionUpdateListener) -> Void
//
	//    typealias IncomingMessageFromBrowserListener = @Sendable (IncomingMessageFromBrowser) -> Void
	//    typealias AddIncomingMessageFromBrowserListener = @Sendable (BrowserExtensionConnection.ID, IncomingMessageFromBrowserListener) -> Void
}

public extension BrowserExtensionsConnectivityClient {
	static let liveValue: Self = {
		@Dependency(\.profileClient) var profileClient

		final class ConnectionsHolder {
			private var connections: [ConnectionID: Connection] = [:]
			static let shared = ConnectionsHolder()
			func addConnection(_ connection: Connection) {
				let key = connection.getConnectionID()
				guard connections[key] == nil else {
					return
				}
				self.connections[key] = connection
				Task.detached {
					try await connection.establish()
				}
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
					connectionsHolder.addConnection(connection)

					return BrowserExtensionConnectionWithState(
						browserExtensionConnection: browserConnection
					)
				}

			},
			addBrowserExtensionConnection: { browserConnection in
				try await profileClient.addBrowserExtensionConnection(browserConnection)
			},
			deleteBrowserExtensionConnection: { id in
				try await profileClient.deleteBrowserExtensionConnection(id)
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

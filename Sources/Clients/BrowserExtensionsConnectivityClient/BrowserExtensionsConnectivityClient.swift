import AsyncExtensions
import Collections
import Common
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
			sendMessage: { _ in fatalError() },
			_sendTestMessage: { _, _ in fatalError() }
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
	public var _sendTestMessage: _SendTestMessage
}

public extension BrowserExtensionsConnectivityClient {
	typealias GetBrowserExtensionConnections = @Sendable () async throws -> [BrowserExtensionWithConnectionStatus]
	typealias AddBrowserExtensionConnection = @Sendable (StatefulBrowserConnection) async throws -> Void
	typealias DeleteBrowserExtensionConnection = @Sendable (BrowserExtensionConnection.ID) async throws -> Void

	typealias GetConnectionStatusAsyncSequence = @Sendable (BrowserExtensionConnection.ID) async throws -> AnyAsyncSequence<BrowserConnectionUpdate>
	typealias GetIncomingMessageAsyncSequence = @Sendable (BrowserExtensionConnection.ID) async throws -> AnyAsyncSequence<IncomingMessageFromBrowser>
	typealias SendMessage = @Sendable (MessageToDappRequest) async throws -> SentMessageToBrowser
	typealias _SendTestMessage = @Sendable (BrowserExtensionConnection.ID, String) async throws -> Void
}

// MARK: - StatefulBrowserConnection
public struct StatefulBrowserConnection: Equatable, Sendable {
	public let browserExtensionConnection: BrowserExtensionConnection
	public private(set) var connection: Connection
	public init(
		browserExtensionConnection: BrowserExtensionConnection,
		connection: Connection
	) {
		self.browserExtensionConnection = browserExtensionConnection
		self.connection = connection
	}
}

// MARK: - NoConnectionMatchingIDFound
struct NoConnectionMatchingIDFound: Swift.Error {}
public extension BrowserExtensionsConnectivityClient {
	static let liveValue: Self = {
		@Dependency(\.profileClient) var profileClient

		final actor ConnectionsHolder: GlobalActor {
			private var connections: [ConnectionID: StatefulBrowserConnection] = [:]
			static let shared = ConnectionsHolder()
			func mapID(_ passwordID: BrowserExtensionConnection.ID) throws -> ConnectionID {
				let connectionPassword = try ConnectionPassword(data: Data(hexString: passwordID))
				return try ConnectionID(password: connectionPassword)
			}

			func addConnection(_ connection: StatefulBrowserConnection, connect: Bool) {
				let key = connection.connection.getConnectionID()
				guard connections[key] == nil else {
					return
				}
				self.connections[key] = connection

				guard connect else { return }

				Task.detached {
					try await connection.connection.establish()
				}
			}

			func disconnectedAndRemove(_ id: BrowserExtensionConnection.ID) {
				guard
					let key = try? mapID(id),
					let _ = connections[key]
				else {
					return
				}
				// connection.connection.close() // when impl in Converse
				connections.removeValue(forKey: key)
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
				return try await connections.connections.asyncMap { browserConnection in

					let password = try ConnectionPassword(data: browserConnection.connectionPassword.data)
					let secrets = try ConnectionSecrets.from(connectionPassword: password)
					let connection = Connection.live(connectionSecrets: secrets)

					let statefulConnection = StatefulBrowserConnection(
						browserExtensionConnection: browserConnection,
						connection: connection
					)

					await connectionsHolder.addConnection(statefulConnection, connect: true)

					return BrowserExtensionWithConnectionStatus(
						browserExtensionConnection: browserConnection
					)
				}

			},
			addBrowserExtensionConnection: { statefulBrowserConnection in
				await connectionsHolder.addConnection(statefulBrowserConnection, connect: false) // should already be connected
				try await profileClient.addBrowserExtensionConnection(statefulBrowserConnection.browserExtensionConnection)
			},
			deleteBrowserExtensionConnection: { id in
				await connectionsHolder.disconnectedAndRemove(id)
				try await profileClient.deleteBrowserExtensionConnection(id)
			},
			getConnectionStatusAsyncSequence: { id in
				let connection = try await connectionsHolder.getConnection(id: id)
				return connection.connection.connectionStatus().map { newStatus in
					BrowserConnectionUpdate(
						connectionStatus: newStatus,
						browserExtensionConnection: connection.browserExtensionConnection
					)
				}.eraseToAnyAsyncSequence()
			},
			getIncomingMessageAsyncSequence: { id in
				let connection = try await connectionsHolder.getConnection(id: id)
				return await connection.connection.receive().compactMap { msg in
					let jsonData = msg.messagePayload
					print(jsonData.prettyPrintedJSONString ?? "got json data")
					do {
						let requestMethodWalletRequest = try JSONDecoder().decode(RequestMethodWalletRequest.self, from: jsonData)

						return try IncomingMessageFromBrowser(
							requestMethodWalletRequest: requestMethodWalletRequest,
							browserExtensionConnection: connection.browserExtensionConnection
						)
					} catch {
						print("⛔️ failed to JSON decode data, error: \(String(describing: error))")
						return nil
					}

				}.eraseToAnyAsyncSequence()
			},
			sendMessage: { outgoingMsg in
				let connection = try await connectionsHolder.getConnection(id: outgoingMsg.browserExtensionConnectionID)
				let data = try outgoingMsg.data()
				let requestID = outgoingMsg.requestID

				try await connection.connection.send(
					Connection.OutgoingMessage(
						data: data,
						id: requestID
					)
				)

				for try await receipt in connection.connection.sentReceipts() {
					guard receipt.messageID == requestID else { continue }
					return SentMessageToBrowser(
						sentReceipt: receipt,
						requestMethodWalletResponse: outgoingMsg.requestMethodWalletResponse,
						browserExtensionConnection: connection.browserExtensionConnection
					)
				}
				throw FailedToReceiveSentReceiptForSuccessfullyDispatchedMsgToDapp()
			},
			_sendTestMessage: { id, message in
				let connection = try await connectionsHolder.getConnection(id: id)
				let outgoingMessage = Connection.OutgoingMessage(
					data: Data(message.utf8),
					id: UUID().uuidString
				)

				try await connection.connection.send(outgoingMessage)
			}
		)
	}()
}

// MARK: - FailedToReceiveSentReceiptForSuccessfullyDispatchedMsgToDapp
struct FailedToReceiveSentReceiptForSuccessfullyDispatchedMsgToDapp: Swift.Error {}

// MARK: - MessageToDappRequest
public struct MessageToDappRequest: Sendable, Equatable, Identifiable {
	public let browserExtensionConnectionID: BrowserExtensionConnection.ID
	public let requestMethodWalletResponse: RequestMethodWalletResponse
	public init(
		browserExtensionConnectionID: BrowserExtensionConnection.ID,
		requestMethodWalletResponse: RequestMethodWalletResponse
	) {
		self.browserExtensionConnectionID = browserExtensionConnectionID
		self.requestMethodWalletResponse = requestMethodWalletResponse
	}
}

public extension MessageToDappRequest {
	func data(jsonEncoder: JSONEncoder = .init()) throws -> Data {
		try jsonEncoder.encode(requestMethodWalletResponse)
	}

	var requestID: RequestMethodWalletResponse.RequestID {
		requestMethodWalletResponse.requestId
	}

	typealias ID = RequestMethodWalletResponse.RequestID
	var id: ID { requestID }
}

// MARK: - SentMessageToBrowser
public struct SentMessageToBrowser: Sendable, Equatable, Identifiable {
	public let sentReceipt: SentReceipt
	public let requestMethodWalletResponse: RequestMethodWalletResponse
	public let browserExtensionConnection: BrowserExtensionConnection
	public init(
		sentReceipt: SentReceipt,
		requestMethodWalletResponse: RequestMethodWalletResponse,
		browserExtensionConnection: BrowserExtensionConnection
	) {
		precondition(sentReceipt.messageID == requestMethodWalletResponse.requestId)
		self.sentReceipt = sentReceipt
		self.requestMethodWalletResponse = requestMethodWalletResponse
		self.browserExtensionConnection = browserExtensionConnection
	}
}

public extension SentMessageToBrowser {
	typealias SentReceipt = Connection.ConfirmedSentMessage
	typealias ID = RequestMethodWalletResponse.RequestID
	var id: ID { requestMethodWalletResponse.requestId }
}

// MARK: - IncomingMessageFromBrowser
public struct IncomingMessageFromBrowser: Sendable, Equatable, Identifiable {
	public struct InvalidRequestFromDapp: Swift.Error, Equatable, CustomStringConvertible {
		public let description: String
	}

	public let requestMethodWalletRequest: RequestMethodWalletRequest

	// FIXME: Post E2E remove this property
	public let payload: RequestMethodWalletRequest.Payload

	public let browserExtensionConnection: BrowserExtensionConnection
	public init(
		requestMethodWalletRequest: RequestMethodWalletRequest,
		browserExtensionConnection: BrowserExtensionConnection
	) throws {
		// FIXME: Post E2E remove this `guard`
		guard
			let payload = requestMethodWalletRequest.payloads.first,
			requestMethodWalletRequest.payloads.count == 1
		else {
			throw InvalidRequestFromDapp(description: "For E2E test we can only handle one single `payload` inside a request from dApp. But got: \(requestMethodWalletRequest.payloads.count)")
		}
		self.payload = payload
		self.requestMethodWalletRequest = requestMethodWalletRequest
		self.browserExtensionConnection = browserExtensionConnection
	}
}

public extension IncomingMessageFromBrowser {
	typealias ID = RequestMethodWalletRequest.RequestID
	var id: ID {
		requestMethodWalletRequest.requestId
	}
}

// MARK: - BrowserConnectionUpdate
public struct BrowserConnectionUpdate: Sendable, Equatable, Identifiable {
	public let connectionStatus: Connection.State
	public let browserExtensionConnection: BrowserExtensionConnection
}

public extension BrowserConnectionUpdate {
	typealias ID = BrowserExtensionConnection.ID
	var id: ID {
		browserExtensionConnection.id
	}
}

#if DEBUG
public extension BrowserExtensionConnection {
	static let placeholder = try! Self(
		computerName: "Placeholder",
		browserName: "Placeholder",
		connectionPassword: Data(hexString: "deadbeeffadedeafdeadbeeffadedeafdeadbeeffadedeafdeadbeeffadedeaf")
	)
}
#endif // DEBUG

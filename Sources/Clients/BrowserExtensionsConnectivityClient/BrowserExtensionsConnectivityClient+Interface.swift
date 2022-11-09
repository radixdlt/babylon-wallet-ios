import AsyncExtensions
import Collections
import Common
import Converse
import ConverseCommon
import Foundation
import ProfileClient
import XCTestDynamicOverlay

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

// MARK: - BrowserExtensionsConnectivityClient

//  MARK: - BrowerExtensionsConnectivity
public struct BrowserExtensionsConnectivityClient {
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

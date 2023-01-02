import AsyncExtensions
import Collections
import Common
import Dependencies
import Foundation
import P2PConnection
import P2PModels
import ProfileClient
import SharedModels
import XCTestDynamicOverlay

// MARK: - DependencyValues
public extension DependencyValues {
	var p2pConnectivityClient: P2PConnectivityClient {
		get { self[P2PConnectivityClient.self] }
		set { self[P2PConnectivityClient.self] = newValue }
	}
}

// MARK: - P2PConnectivityClient

//  MARK: - P2PConnectivityClient
public struct P2PConnectivityClient: DependencyKey, Sendable {
	public var getLocalNetworkAccess: GetLocalNetworkAccess
	public var getP2PClients: GetP2PClients
	public var addP2PClientWithConnection: AddP2PClientWithConnection
	public var deleteP2PClientByID: DeleteP2PClientByID

	public var getConnectionStatusAsyncSequence: GetConnectionStatusAsyncSequence
	public var getRequestsFromP2PClientAsyncSequence: GetRequestsFromP2PClientAsyncSequence
	public var sendMessageReadReceipt: SendMessageReadReceipt
	public var sendMessage: SendMessage
	public var _sendTestMessage: _SendTestMessage
}

public extension P2PConnectivityClient {
	typealias GetLocalNetworkAccess = @Sendable () async -> Bool
	typealias GetP2PClients = @Sendable () async throws -> AsyncStream<OrderedSet<P2P.ClientWithConnectionStatus>>

	typealias AddP2PClientWithConnection = @Sendable (P2PClient, AlsoConnect) async throws -> Void; typealias AlsoConnect = Bool
	typealias DeleteP2PClientByID = @Sendable (P2PClient.ID) async throws -> Void

	typealias GetConnectionStatusAsyncSequence = @Sendable (P2PClient.ID) async throws -> AnyAsyncSequence<P2P.ConnectionUpdate>
	typealias GetRequestsFromP2PClientAsyncSequence = @Sendable (P2PClient.ID) async throws -> AsyncStream<P2P.RequestFromClient>

	typealias SendMessageReadReceipt = @Sendable (P2PClient.ID, P2PConnections.IncomingMessage) async throws -> Void
	typealias SendMessage = @Sendable (P2P.ResponseToClientByID) async throws -> P2P.SentResponseToClient
	typealias _SendTestMessage = @Sendable (P2PClient.ID, String) async throws -> Void
}

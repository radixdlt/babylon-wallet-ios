import AsyncExtensions
import Collections
import Common
import Dependencies
import Foundation
import Models
import Peer
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

	typealias Element = [P2P.ConnectionForClient]
	typealias Base = AsyncThrowingReplaySubject<Element, any Error>
	typealias Subject = AsyncThrowingPassthroughSubject<Element, any Error>
	typealias Multicasted = AsyncMulticastSequence<Base, Subject>

	typealias GetP2PClients = @Sendable () async throws -> Multicasted

	typealias AddP2PClientWithConnection = @Sendable (P2P.ConnectionForClient, AlsoConnect) async throws -> Void; typealias AlsoConnect = Bool
	typealias DeleteP2PClientByID = @Sendable (P2PClient.ID) async throws -> Void

	typealias GetConnectionStatusAsyncSequence = @Sendable (P2PClient.ID) async throws -> AnyAsyncSequence<P2P.ConnectionUpdate>
	typealias GetRequestsFromP2PClientAsyncSequence = @Sendable (P2PClient.ID) async throws -> AnyAsyncSequence<P2P.RequestFromClient>
	typealias SendMessageReadReceipt = @Sendable (P2PClient.ID, Peer.IncomingMessage) async throws -> Void
	typealias SendMessage = @Sendable (P2P.ResponseToClientByID) async throws -> P2P.SentResponseToClient
	typealias _SendTestMessage = @Sendable (P2PClient.ID, String) async throws -> Void
}

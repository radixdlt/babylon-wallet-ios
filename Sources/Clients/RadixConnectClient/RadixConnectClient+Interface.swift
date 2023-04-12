import ClientPrelude
import RadixConnect

// MARK: - DependencyValues
extension DependencyValues {
	public var radixConnectClient: RadixConnectClient {
		get { self[RadixConnectClient.self] }
		set { self[RadixConnectClient.self] = newValue }
	}
}

// MARK: - RadixConnectClient
public struct RadixConnectClient: DependencyKey, Sendable {
	public var loadFromProfileAndConnectAll: LoadFromProfileAndConnectAll
	public var disconnectAndRemoveAll: DisconnectAndRemoveAll
	public var disconnectAll: DisconnectAll

	public var getLocalNetworkAccess: GetLocalNetworkAccess

	public var getP2PLinks: GetP2PLinks
	public var storeP2PLink: StoreP2PLink
	public var deleteP2PLinkByPassword: DeleteP2PLinkByPassword
	public var addP2PWithPassword: AddP2PWithPassword

	public var receiveMessages: ReceiveMessages
	public var sendMessage: SendMessage
}

extension RadixConnectClient {
	public typealias LoadFromProfileAndConnectAll = @Sendable () async -> Void
	public typealias DisconnectAndRemoveAll = @Sendable () async -> Void
	public typealias DisconnectAll = @Sendable () async -> Void

	public typealias GetLocalNetworkAccess = @Sendable () async -> Bool

	public typealias GetP2PLinks = @Sendable () async throws -> OrderedSet<P2PLink>
	public typealias StoreP2PLink = @Sendable (P2PLink) async throws -> Void

	public typealias AddP2PWithPassword = @Sendable (ConnectionPassword) async throws -> Void
	public typealias DeleteP2PLinkByPassword = @Sendable (ConnectionPassword) async throws -> Void

	public typealias ReceiveMessages = @Sendable () async -> AsyncStream<P2P.RTCIncomingMessage>
	public typealias SendMessage = @Sendable (P2P.RTCOutgoingMessage) async throws -> Void
}

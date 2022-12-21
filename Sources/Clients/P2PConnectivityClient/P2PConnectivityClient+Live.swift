import AsyncAlgorithms
import AsyncExtensions
import Dependencies
import Foundation
import JSON
import Network
import Peer
import ProfileClient
import SharedModels

// MARK: - P2PConnectivityClient + :LiveValue
public extension P2PConnectivityClient {
	static let liveValue: Self = {
		@Dependency(\.profileClient) var profileClient

		final actor ConnectionsHolder: GlobalActor {
			private var connections: [ConnectionID: P2P.ConnectionForClient]
			private let justClientsWithStatusChannel: AsyncChannel<[P2P.ClientWithConnectionStatus]> = .init()
			fileprivate nonisolated var justClientsWithStatusAsyncSequence: AnyAsyncSequence<[P2P.ClientWithConnectionStatus]> {
				justClientsWithStatusChannel.eraseToAnyAsyncSequence()
			}

			private let base: P2PConnectivityClient.Base
			private let subject: P2PConnectivityClient.Subject
			fileprivate nonisolated let multicasted: P2PConnectivityClient.Multicasted

			init() {
				connections = [:]

				let base: Base = .init(bufferSize: 1)
				let subject: Subject = .init()
				let multicasted: Multicasted = base.multicast(subject)

				self.base = base
				self.subject = subject
				self.multicasted = multicasted
			}

			static let shared = ConnectionsHolder()

			func mapID(_ passwordID: P2PClient.ID) throws -> ConnectionID {
				let connectionPassword = try ConnectionPassword(data: Data(hexString: passwordID))
				return try ConnectionID(password: connectionPassword)
			}

			@Sendable func emit() async {
				base.send(
					connections.values.map { $0 }
				)
				Task {
					await justClientsWithStatusChannel.send(
						connections.values.map { .init(p2pClient: $0.client, connectionStatus: .new) }
					)
				}
			}

			func addConnection(_ connection: P2P.ConnectionForClient, connect: Bool, emitUpdate: Bool) async {
				let key = connection.peer.connectionID
				guard connections[key] == nil else {
					return
				}
				self.connections[key] = connection
				guard connect else {
					if emitUpdate {
						await emit()
					}
					return
				}
				Task { [connection] in
					try await connection.peer.connect()
				}
				guard emitUpdate else {
					return
				}
				await emit()
			}

			func disconnectedAndRemove(_ id: P2PClient.ID) async {
				guard
					let key = try? mapID(id),
					let _ = connections[key]
				else {
					return
				}
				if let removed = connections.removeValue(forKey: key) {
					await removed.peer.disconnect()
				}
				await emit()
			}

			func getConnection(id: P2PClient.ID) async -> P2P.ConnectionForClient? {
				guard
					let key = try? mapID(id)
				else {
					return nil
				}
				guard
					let peer = connections[key]
				else {
					return nil
				}
				return peer
			}

			func loadedFromProfile(connections: P2PClients) async throws {
				for connection in self.connections.values {
					if !connections.connections.contains(connection.client) {
						await self.disconnectedAndRemove(connection.client.id)
					}
				}
				for p2pClient in connections.connections {
					let password = try ConnectionPassword(data: p2pClient.connectionPassword.data)
					let secrets = try ConnectionSecrets.from(connectionPassword: password)
					let peer = Peer(connectionSecrets: secrets)

					let connectedClient = P2P.ConnectionForClient(
						client: p2pClient,
						peer: peer
					)
					await self.addConnection(connectedClient, connect: true, emitUpdate: false)
				}
				await self.emit()
			}
		}

		let connectionsHolder = ConnectionsHolder.shared

		@Sendable func loadFromProfile() async throws {
			let connections = try await profileClient.getP2PClients()
			try await connectionsHolder.loadedFromProfile(connections: connections)
		}

		let localNetworkAuthorization = LocalNetworkAuthorization()

		return Self(
			getLocalNetworkAccess: {
				await localNetworkAuthorization.requestAuthorization()
			},
			getP2PClients: {
				try await loadFromProfile()
				return connectionsHolder.justClientsWithStatusAsyncSequence
			},
			getP2PConnections: {
				try await loadFromProfile()
				return connectionsHolder.multicasted.autoconnect()
			},
			addP2PClientWithConnection: { clientWithConnection, alsoConnect in
				try await profileClient.addP2PClient(clientWithConnection.client)
				await connectionsHolder.addConnection(clientWithConnection, connect: alsoConnect, emitUpdate: true)
			},
			deleteP2PClientByID: { id in
				try await profileClient.deleteP2PClientByID(id)
				await connectionsHolder.disconnectedAndRemove(id)
			},
			getConnectionStatusAsyncSequence: { id in
				guard let connection = await connectionsHolder.getConnection(id: id) else {
					return AsyncLazySequence([]).eraseToAnyAsyncSequence()
				}
				return await connection.peer.connectionStatusPublisher.map { newStatus in
					P2P.ConnectionUpdate(
						connectionStatus: newStatus,
						p2pClient: connection.client
					)
				}
				.values
				.eraseToAnyAsyncSequence()
			},
			getRequestsFromP2PClientAsyncSequence: { id in
				guard let connection = await connectionsHolder.getConnection(id: id) else {
					return AsyncLazySequence([]).eraseToAnyAsyncSequence()
				}
				return await connection.peer.incomingMessagesPublisher.tryMap { (msg: ChunkingTransportIncomingMessage) in
					@Dependency(\.jsonDecoder) var jsonDecoder

					let jsonData = msg.messagePayload
					do {
						let requestFromDapp = try jsonDecoder().decode(P2P.FromDapp.Request.self, from: jsonData)

						return try P2P.RequestFromClient(
							originalMessage: msg,
							requestFromDapp: requestFromDapp,
							client: connection.client
						)
					} catch {
						throw FailedToDecodeRequestFromDappError(
							error: error,
							jsonString: String(data: jsonData, encoding: .utf8) ?? jsonData.hex
						)
					}
				}.values.eraseToAnyAsyncSequence()
			},
			sendMessageReadReceipt: { id, readMessage in
				guard let connection = await connectionsHolder.getConnection(id: id) else {
					throw NoConnection()
				}
				try await connection.peer.sendReadReceipt(for: readMessage)
			},
			sendMessage: { outgoingMsg in
				@Dependency(\.jsonEncoder) var jsonEncoder

				guard let connection = await connectionsHolder.getConnection(id: outgoingMsg.connectionID) else {
					throw NoConnection()
				}
				let responseToDappData = try jsonEncoder().encode(outgoingMsg.responseToDapp)
				let p2pChannelRequestID = UUID().uuidString

				try await connection.peer.send(
					data: responseToDappData,
					id: p2pChannelRequestID
				)

				for try await receipt in await connection.peer.sentReceiptsPublisher.values {
					guard receipt.messageSent.messageID == p2pChannelRequestID else { continue }
					return P2P.SentResponseToClient(
						sentReceipt: receipt,
						responseToDapp: outgoingMsg.responseToDapp,
						client: connection.client
					)
				}
				throw FailedToReceiveSentReceiptForSuccessfullyDispatchedMsgToDapp()
			},
			_sendTestMessage: { id, message in
				guard let connection = await connectionsHolder.getConnection(id: id) else {
					print("No connection found for: \(id)")
					return
				}
				do {
					try await connection.peer.send(data: Data(message.utf8), id: UUID().uuidString)
				} catch {
					print("Failed to send test message, error: \(String(describing: error))")
				}

				// does not care about sent message receipts
			}
		)
	}()
}

// MARK: - NoConnection
struct NoConnection: LocalizedError {
	init() {}
	var errorDescription: String? {
		"Connection offline."
	}
}

// MARK: - LocalNetworkAuthorization
/// Source: https://stackoverflow.com/a/67758105/705761
private final class LocalNetworkAuthorization: NSObject, @unchecked Sendable {
	private var browser: NWBrowser?
	private var netService: NetService?
	private var completion: ((Bool) -> Void)?

	public func requestAuthorization() async -> Bool {
		await withCheckedContinuation { continuation in
			requestAuthorization { result in
				continuation.resume(returning: result)
			}
		}
	}

	private func requestAuthorization(completion: @escaping (Bool) -> Void) {
		self.completion = completion

		// Create parameters, and allow browsing over peer-to-peer link.
		let parameters = NWParameters()
		parameters.includePeerToPeer = true

		// Browse for a custom service type.
		let browser = NWBrowser(for: .bonjour(type: "_bonjour._tcp", domain: nil), using: parameters)
		self.browser = browser
		browser.stateUpdateHandler = { newState in
			switch newState {
			case .setup, .ready, .cancelled:
				break
			case let .failed(error):
				print(error.localizedDescription)
			case let .waiting(error):
				print("Local network permission has been denied: \(error)")
				self.reset()
				self.completion?(false)
			}
		}

		self.netService = NetService(domain: "local.", type: "_lnp._tcp.", name: "LocalNetworkPrivacy", port: 1100)
		self.netService?.delegate = self
		self.netService?.schedule(in: .main, forMode: .common)

		self.browser?.start(queue: .main)
		self.netService?.publish()
	}

	private func reset() {
		self.browser?.cancel()
		self.browser = nil
		self.netService?.stop()
		self.netService = nil
	}
}

// MARK: NetServiceDelegate
extension LocalNetworkAuthorization: NetServiceDelegate {
	func netServiceDidPublish(_ sender: NetService) {
		self.reset()
		print("Local network permission has been granted")
		completion?(true)
	}
}

// MARK: - FailedToReceiveSentReceiptForSuccessfullyDispatchedMsgToDapp
struct FailedToReceiveSentReceiptForSuccessfullyDispatchedMsgToDapp: Swift.Error {}

// MARK: - FailedToDecodeRequestFromDappError
public struct FailedToDecodeRequestFromDappError: LocalizedError {
	public let error: Error
	public let jsonString: String
	public init(error: Error, jsonString: String) {
		self.error = error
		self.jsonString = jsonString
	}

	public var errorDescription: String? {
		"Failed to decode request from Dapp got: \(jsonString)\nerror: \(String(describing: error))"
	}
}

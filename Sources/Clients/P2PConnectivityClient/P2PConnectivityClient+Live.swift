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
			private var connections: [ConnectionID: P2P.ConnectionForClient] = [:]
			var p2pClients: AsyncCurrentValueSubject<[P2P.ClientWithConnectionStatus]> = .init([])
			static let shared = ConnectionsHolder()

			func mapID(_ passwordID: P2PClient.ID) throws -> ConnectionID {
				let connectionPassword = try ConnectionPassword(data: Data(hexString: passwordID))
				return try ConnectionID(password: connectionPassword)
			}

			func addConnection(_ connection: P2P.ConnectionForClient, connect: Bool, emitUpdate: Bool) {
				let key = connection.peer.connectionID
				guard connections[key] == nil else {
					return
				}
				self.connections[key] = connection
				guard connect else {
					if emitUpdate {
						p2pClients.send(p2pClients.value + [.init(p2pClient: connection.client, connectionStatus: .connected)])
					}
					return
				}

				Task.detached { [p2pClients] in
					try await connection.peer.connect()
					if emitUpdate {
						p2pClients.send(p2pClients.value + [.init(p2pClient: connection.client, connectionStatus: .connected)])
					}
				}
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
				var value = p2pClients.value
				value.removeAll(where: { $0.p2pClient.id == id })
				p2pClients.send(value)
			}

			func getConnection(id: P2PClient.ID) -> P2P.ConnectionForClient? {
				guard
					let key = try? mapID(id),
					let peer = connections[key]
				else {
					return nil
				}
				return peer
			}
		}

		let connectionsHolder = ConnectionsHolder.shared

		let localNetworkAuthorization = LocalNetworkAuthorization()

		return Self(
			getLocalNetworkAuthorization: {
				await localNetworkAuthorization.requestAuthorization()
			},
			getP2PClients: {
				let connections = try await profileClient.getP2PClients()
				let clientsWithConnectionStatus = try await connections.connections.asyncMap { p2pClient in

					let password = try ConnectionPassword(data: p2pClient.connectionPassword.data)
					let secrets = try ConnectionSecrets.from(connectionPassword: password)
					let peer = Peer(connectionSecrets: secrets)

					let connectedClient = P2P.ConnectionForClient(
						client: p2pClient,
						peer: peer
					)

					await connectionsHolder.addConnection(connectedClient, connect: true, emitUpdate: false)

					return P2P.ClientWithConnectionStatus(p2pClient: p2pClient)
				}
				await connectionsHolder.p2pClients.send(clientsWithConnectionStatus)
				return await connectionsHolder.p2pClients.eraseToAnyAsyncSequence()

			},
			addP2PClientWithConnection: { clientWithConnection, alsoConnect in
				await connectionsHolder.addConnection(clientWithConnection, connect: alsoConnect, emitUpdate: true)
				try await profileClient.addP2PClient(clientWithConnection.client)
			},
			deleteP2PClientByID: { id in
				await connectionsHolder.disconnectedAndRemove(id)
				try await profileClient.deleteP2PClientByID(id)
			},
			getConnectionStatusAsyncSequence: { id in
				guard let connection = await connectionsHolder.getConnection(id: id) else {
					return [P2P.ConnectionUpdate]().async.eraseToAnyAsyncSequence()
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
					return [P2P.RequestFromClient]().async.eraseToAnyAsyncSequence()
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
					struct NoConnection: LocalizedError {
						init() {}
						var errorDescription: String? {
							"Connection offline."
						}
					}
					throw NoConnection()
				}
//				try await connection.peer.sendReadReceipt(messageID: msgID)
				try await connection.peer.sendReadReceipt(for: readMessage)
			},
			sendMessage: { outgoingMsg in
				@Dependency(\.jsonEncoder) var jsonEncoder

				guard let connection = await connectionsHolder.getConnection(id: outgoingMsg.connectionID) else {
					struct NoConnection: LocalizedError {
						init() {}
						var errorDescription: String? {
							"Connection offline."
						}
					}
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
				let connection = await connectionsHolder.getConnection(id: id)
				try await connection?.peer.send(data: Data(message.utf8), id: UUID().uuidString)

				// does not care about sent message receipts
			}
		)
	}()
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

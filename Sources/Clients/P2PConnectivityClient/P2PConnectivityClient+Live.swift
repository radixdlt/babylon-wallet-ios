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
				print("🚨 emitting: \(connections.values.map(\.client.displayName))")
				base.send(
					connections.values.map { $0 }
				)
				print("🚨 emmitted!")
			}

			func addConnection(_ connection: P2P.ConnectionForClient, connect: Bool, emitUpdate: Bool) async {
				print("💩 addConnection START")
				let key = connection.peer.connectionID
				guard connections[key] == nil else {
					print("💩 addConnection key exists, returning...")
					return
				}
				self.connections[key] = connection
				print("💩 addConnection set connection for key")
				guard connect else {
					print("💩 addConnection not connecting...")
					if emitUpdate {
						print("💩 addConnection emitting,..?")
						await emit()
						print("💩 addConnection emitted!")
					}
					print("💩 addConnection return from guard")
					return
				}
				print("💩 addConnection detatch connecting..")
				Task.detached { [connection] in
					try await connection.peer.connect()
				}
				print("💩 addConnection detatch connected end")
				guard emitUpdate else {
					print("💩 addConnection not emit, returning")
					return
				}
				print("💩 addConnection emitting..?")
				await emit()
				print("💩 addConnection emitted!?")
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
				print("🫁 getting connection for ID: \(id)")
				guard
					let key = try? mapID(id)
				else {
					print("🫁 failed to map id to key")
					return nil
				}
				guard
					let peer = connections[key]
				else {
					print("🫁 no connection found for: \(id) or key=\(key), only have: \(connections.values)")
					return nil
				}
				print("🫁 got connection for ID: \(id)")
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
				print("🧝‍♀️ getP2PClients start")
				let connections = try await profileClient.getP2PClients()
				print("🧝‍♀️ getP2PClients read #\(connections.connections.count) connections from profile")
				let clientsWithConnectionStatus = try await connections.connections.asyncMap { p2pClient in
					print("🧝‍♀️ getP2PClients async map to peer START")

					let password = try ConnectionPassword(data: p2pClient.connectionPassword.data)
					print("🧝‍♀️ getP2PClients async map to peer created password")
					let secrets = try ConnectionSecrets.from(connectionPassword: password)
					print("🧝‍♀️ getP2PClients async map to peer created secrets")
					let peer = Peer(connectionSecrets: secrets)
					print("🧝‍♀️ getP2PClients async map to peer created peer")

					let connectedClient = P2P.ConnectionForClient(
						client: p2pClient,
						peer: peer
					)
					print("🧝‍♀️ getP2PClients async map to peer created connectedClient")
					await connectionsHolder.addConnection(connectedClient, connect: true, emitUpdate: false)
					print("🧝‍♀️ getP2PClients async map to added Connection to connections holder")

					print("🧝‍♀️ getP2PClients async map to peer END")
					return P2P.ClientWithConnectionStatus(p2pClient: p2pClient)
				}
				print("🧝‍♀️ getP2PClients async mapped ALL to peer")
				Task.detached {
					print("🧝‍♀️ emitting detatched")
					await connectionsHolder.emit()
					print("🧝‍♀️ emitted detatched")
				}
				print("🧝‍♀️ returning asyncSequence")
				return connectionsHolder.multicasted.autoconnect()

			},
			addP2PClientWithConnection: { clientWithConnection, alsoConnect in
				try await profileClient.addP2PClient(clientWithConnection.client)
				print("🎃 adding new and emitting!")
				await connectionsHolder.addConnection(clientWithConnection, connect: alsoConnect, emitUpdate: true)
				print("🎃 adding new finished!")
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
				print("👹 getRequestsFromP2PClientAsyncSequence START id=\(id)")
				guard let connection = await connectionsHolder.getConnection(id: id) else {
					print("👹 getRequestsFromP2PClientAsyncSequence not found for connectionID: \(id)")
					return AsyncLazySequence([]).eraseToAnyAsyncSequence()
				}
				print("👹 getRequestsFromP2PClientAsyncSequence connection.name: \(connection.client.displayName)")
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
				print("💄 Sending test message to connection with id: \(id)")
				guard let connection = await connectionsHolder.getConnection(id: id) else {
					print("💄 no connection found for: \(id)")
					return
				}
				print("💄 got connection, will try to send message...")
				do {
					try await connection.peer.send(data: Data(message.utf8), id: UUID().uuidString)
					print("💄✅ successfully sent message?! :D ")
				} catch {
					print("💄 failed to send test message, error: \(String(describing: error))")
				}

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

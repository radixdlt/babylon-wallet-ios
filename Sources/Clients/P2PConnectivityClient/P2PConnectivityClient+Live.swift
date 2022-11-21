import AsyncExtensions
import Converse
import ConverseCommon
import Dependencies
import Foundation
import JSON
import ProfileClient
import SharedModels

// MARK: - P2PConnectivityClient + DependencyKey
extension P2PConnectivityClient: DependencyKey {
	public static let liveValue: Self = {
		@Dependency(\.profileClient) var profileClient

		final actor ConnectionsHolder: GlobalActor {
			private var connections: [ConnectionID: P2P.ConnectedClient] = [:]
			public var p2pClients: AsyncCurrentValueSubject<[P2P.ClientWithConnectionStatus]> = .init([])
			static let shared = ConnectionsHolder()

			func mapID(_ passwordID: P2PClient.ID) throws -> ConnectionID {
				let connectionPassword = try ConnectionPassword(data: Data(hexString: passwordID))
				return try ConnectionID(password: connectionPassword)
			}

			func addConnection(_ connection: P2P.ConnectedClient, connect: Bool, emitUpdate: Bool) {
				let key = connection.connection.getConnectionID()
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
					try await connection.connection.establish()
					if emitUpdate {
						p2pClients.send(p2pClients.value + [.init(p2pClient: connection.client, connectionStatus: .connected)])
					}
				}
			}

			func disconnectedAndRemove(_ id: P2PClient.ID) {
				guard
					let key = try? mapID(id),
					let _ = connections[key]
				else {
					return
				}
				// connection.connection.close() // when impl in Converse
				connections.removeValue(forKey: key)
				var value = p2pClients.value
				value.removeAll(where: { $0.p2pClient.id == id })
				p2pClients.send(value)
			}

			func getConnection(id: P2PClient.ID) throws -> P2P.ConnectedClient {
				let key = try mapID(id)
				guard let connection = connections[key] else {
					struct NoConnectionMatchingIDFound: Swift.Error {}
					throw NoConnectionMatchingIDFound()
				}
				return connection
			}
		}

		let connectionsHolder = ConnectionsHolder.shared

		return Self(
			getP2PClients: {
				let connections = try profileClient.getP2PClients()
				let clientsWithConnectionStatus = try await connections.connections.asyncMap { p2pClient in

					let password = try ConnectionPassword(data: p2pClient.connectionPassword.data)
					let secrets = try ConnectionSecrets.from(connectionPassword: password)
					let connection = Connection.live(connectionSecrets: secrets)

					let connectedClient = P2P.ConnectedClient(
						client: p2pClient,
						connection: connection
					)

					await connectionsHolder.addConnection(connectedClient, connect: true, emitUpdate: false)

					return P2P.ClientWithConnectionStatus(p2pClient: p2pClient)
				}
				await connectionsHolder.p2pClients.send(clientsWithConnectionStatus)
				return await connectionsHolder.p2pClients.eraseToAnyAsyncSequence()

			},
			addConnectedP2PClient: { connectedClient in
				await connectionsHolder.addConnection(connectedClient, connect: false, emitUpdate: true) // should already be connected
				try await profileClient.addP2PClient(connectedClient.client)
			},
			deleteP2PClientByID: { id in
				await connectionsHolder.disconnectedAndRemove(id)
				try await profileClient.deleteP2PClientByID(id)
			},
			getConnectionStatusAsyncSequence: { id in
				let connection = try await connectionsHolder.getConnection(id: id)
				return connection.connection.connectionStatus().map { newStatus in
					P2P.ConnectionUpdate(
						connectionStatus: newStatus,
						p2pClient: connection.client
					)
				}.eraseToAnyAsyncSequence()
			},
			getRequestsFromP2PClientAsyncSequence: { id in
				let connection = try await connectionsHolder.getConnection(id: id)
				return await connection.connection.receive().map { msg in
					@Dependency(\.jsonDecoder) var jsonDecoder

					let jsonData = msg.messagePayload
					let requestFromDapp = try jsonDecoder().decode(P2P.FromDapp.Request.self, from: jsonData)

					return try P2P.RequestFromClient(
						requestFromDapp: requestFromDapp,
						client: connection.client
					)

				}.eraseToAnyAsyncSequence()
			},
			sendMessage: { outgoingMsg in
				@Dependency(\.jsonEncoder) var jsonEncoder

				let connection = try await connectionsHolder.getConnection(id: outgoingMsg.connectionID)
				let responseToDappData = try jsonEncoder().encode(outgoingMsg.responseToDapp)
				let p2pChannelRequestID = UUID().uuidString

				try await connection.connection.send(
					Connection.OutgoingMessage(
						data: responseToDappData,
						id: p2pChannelRequestID
					)
				)

				for try await receipt in connection.connection.sentReceipts() {
					guard receipt.messageID == p2pChannelRequestID else { continue }
					return P2P.SentResponseToClient(
						sentReceipt: receipt,
						responseToDapp: outgoingMsg.responseToDapp,
						client: connection.client
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

				// does not care about sent message receipts
			}
		)
	}()
}

// MARK: - FailedToReceiveSentReceiptForSuccessfullyDispatchedMsgToDapp
struct FailedToReceiveSentReceiptForSuccessfullyDispatchedMsgToDapp: Swift.Error {}

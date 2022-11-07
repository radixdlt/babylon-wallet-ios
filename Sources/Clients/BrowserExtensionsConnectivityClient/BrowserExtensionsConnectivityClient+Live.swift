import Converse
import ConverseCommon
import Dependencies
import Foundation
import ProfileClient

// MARK: - BrowserExtensionsConnectivityClient + DependencyKey
extension BrowserExtensionsConnectivityClient: DependencyKey {
	public static let liveValue: Self = {
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
					struct NoConnectionMatchingIDFound: Swift.Error {}
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
				return await connection.connection.receive().map { msg in
					let jsonData = msg.messagePayload
					let requestMethodWalletRequest = try JSONDecoder().decode(RequestMethodWalletRequest.self, from: jsonData)

					return try IncomingMessageFromBrowser(
						requestMethodWalletRequest: requestMethodWalletRequest,
						browserExtensionConnection: connection.browserExtensionConnection
					)

				}.eraseToAnyAsyncSequence()
			},
			sendMessage: { outgoingMsg in
				let connection = try await connectionsHolder.getConnection(id: outgoingMsg.browserExtensionConnectionID)
				let data = try outgoingMsg.data()
				let p2pChannelRequestID = UUID().uuidString

				try await connection.connection.send(
					Connection.OutgoingMessage(
						data: data,
						id: p2pChannelRequestID
					)
				)

				for try await receipt in connection.connection.sentReceipts() {
					guard receipt.messageID == p2pChannelRequestID else { continue }
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

				// does not care about sent message receipts
			}
		)
	}()
}

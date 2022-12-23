import AsyncAlgorithms
import AsyncExtensions
import Dependencies
import Foundation
import JSON
import Network
import P2PConnection
import ProfileClient
import Resources
import SharedModels

// MARK: - P2PConnectivityClient + :LiveValue
public extension P2PConnectivityClient {
	static let liveValue: Self = {
		@Dependency(\.profileClient) var profileClient

		//        actor ConnectionsHolder: GlobalActor {
		//            init() {}
		//            static let shared = ConnectionsHolder()
		//        }

		let localNetworkAuthorization = LocalNetworkAuthorization()

		return Self(
			getLocalNetworkAccess: {
				await localNetworkAuthorization.requestAuthorization()
			},
			getP2PClients: {
				//                try await ConnectionsHolder.shared.getP2PClients()
				fatalError()
			},
			addP2PClientWithConnection: { _, _ in
//				try await profileClient.addP2PClient(clientWithConnection.client)
//				await connectionsHolder.addConnection(clientWithConnection, connect: alsoConnect, emitUpdate: true)
				fatalError()
			},
			deleteP2PClientByID: { _ in
//				try await profileClient.deleteP2PClientByID(id)
//				await connectionsHolder.disconnectedAndRemove(id)
				fatalError()
			},
			getConnectionStatusAsyncSequence: { _ in
				fatalError()
			},
			getRequestsFromP2PClientAsyncSequence: { _ in
//				guard let connection = await connectionsHolder.getConnection(id: id) else {
//					return AsyncLazySequence([]).eraseToAnyAsyncSequence()
//				}
//				return await connection.p2pConnection.incomingMessagesPublisher.tryMap { (msg: ChunkingTransportIncomingMessage) in
//					@Dependency(\.jsonDecoder) var jsonDecoder
//
//					let jsonData = msg.messagePayload
//					do {
//						let requestFromDapp = try jsonDecoder().decode(P2P.FromDapp.Request.self, from: jsonData)
//
//						return try P2P.RequestFromClient(
//							originalMessage: msg,
//							requestFromDapp: requestFromDapp,
//							client: connection.client
//						)
//					} catch {
//						throw FailedToDecodeRequestFromDappError(
//							error: error,
//							jsonString: String(data: jsonData, encoding: .utf8) ?? jsonData.hex
//						)
//					}
//				}.values.eraseToAnyAsyncSequence()
				fatalError()
			},
			sendMessageReadReceipt: { _, _ in
//				guard let connection = await connectionsHolder.getConnection(id: id) else {
//					throw P2PConnectionOffline()
//				}
//				try await connection.p2pConnection.sendReadReceipt(for: readMessage)
				fatalError()
			},
			sendMessage: { _ in
//				@Dependency(\.jsonEncoder) var jsonEncoder
//
//				guard let connection = await connectionsHolder.getConnection(id: outgoingMsg.connectionID) else {
//					throw P2PConnectionOffline()
//				}
//				let responseToDappData = try jsonEncoder().encode(outgoingMsg.responseToDapp)
//				let p2pChannelRequestID = UUID().uuidString
//
//				try await connection.p2pConnection.send(
//					data: responseToDappData,
//					id: p2pChannelRequestID
//				)
//
//				for try await receipt in await connection.p2pConnection.sentReceiptsPublisher.values {
//					guard receipt.messageSent.messageID == p2pChannelRequestID else { continue }
//					return P2P.SentResponseToClient(
//						sentReceipt: receipt,
//						responseToDapp: outgoingMsg.responseToDapp,
//						client: connection.client
//					)
//				}
//				throw FailedToReceiveSentReceiptForSuccessfullyDispatchedMsgToDapp()
				fatalError()
			},
			_sendTestMessage: { _, _ in
//				guard let connection = await connectionsHolder.getConnection(id: id) else {
//					print("No connection found for: \(id)")
//					return
//				}
//				do {
//					try await connection.p2pConnection.send(data: Data(message.utf8), id: UUID().uuidString)
//				} catch {
//					print("Failed to send test message, error: \(String(describing: error))")
//				}
//
//				// does not care about sent message receipts
				fatalError()
			}
		)
	}()
}

// MARK: - P2PConnectionOffline
struct P2PConnectionOffline: LocalizedError {
	init() {}
	var errorDescription: String? {
		L10n.Common.p2PConnectionOffline
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

		// Create parameters, and allow browsing over p2pConnection-to-p2pConnection link.
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
			@unknown default:
				print("Local network permission unknown state: \(String(describing: newState))")
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

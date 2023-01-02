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

extension P2P.ClientWithConnectionStatus {
	func connected() -> Self {
		.init(p2pClient: p2pClient, connectionStatus: .connected)
	}
}

extension ProfileClient {
	func p2pClient(for id: P2PConnectionID) async throws -> P2PClient? {
		try await getP2PClients().filter { client in
			client.id == id
		}.first
	}
}

// MARK: - P2PConnectivityClient + :LiveValue
public extension P2PConnectivityClient {
	static let liveValue: Self = {
		actor Once: GlobalActor {
			init() {}
			static let shared = Once()
			fileprivate var hasLoadedP2PClientsFromProfile = false
			func setHasLoaded(_ hasLoadedP2PClientsFromProfile: Bool) async {
				self.hasLoadedP2PClientsFromProfile = hasLoadedP2PClientsFromProfile
			}
		}
		@Dependency(\.profileClient) var profileClient

		let localNetworkAuthorization = LocalNetworkAuthorization()

		@Sendable func client(byID id: P2PClient.ID) async throws -> P2PClient {
			guard let client = try await profileClient.p2pClient(for: id) else {
				throw P2PClientNotFoundInProfile()
			}
			return client
		}

		return Self(
			getLocalNetworkAccess: {
				await localNetworkAuthorization.requestAuthorization()
			},
			getP2PClients: {
				if await Once.shared.hasLoadedP2PClientsFromProfile == false {
					let clients = try await profileClient.getP2PClients()
					try await P2PConnections.shared.add(
						connectionsFor: clients,
						autoconnect: true
					)
					await Once.shared.setHasLoaded(true)
				}
				let multicastSubject = AsyncThrowingPassthroughSubject<OrderedSet<P2P.ClientWithConnectionStatus>, Swift.Error>()

				// We MUST make sure to multicast because both HandleDappRequest and ManageP2PClients features use this method `getP2PClients`, and AsyncSequence does not support multicast
				return try await P2PConnections.shared.connectionsAsyncSequence().map { clientIDs in
					try await OrderedSet(
						clientIDs.asyncMap {
							try await profileClient.p2pClient(for: $0)
						}.compactMap { client in
							guard let client else { return nil }
							return P2P.ClientWithConnectionStatus(p2pClient: client, connectionStatus: .connected)
						}
					)
				}
				.multicast(multicastSubject)
				.autoconnect()
				.eraseToAnyAsyncSequence()
			},
			addP2PClientWithConnection: { client, autoconnect in
				try await profileClient.addP2PClient(client)
				_ = try await P2PConnections.shared.add(config: client.config, autoconnect: autoconnect)
			},
			deleteP2PClientByID: { id in
				try await profileClient.deleteP2PClientByID(id)
				try await P2PConnections.shared.removeAndDisconnect(id: id)
			},
			getConnectionStatusAsyncSequence: { id in
				try await P2PConnections.shared.connectionStatusChangeEventAsyncSequence(for: id).map {
					try await P2P.ConnectionUpdate(
						connectionStatus: $0.connectionStatus,
						p2pClient: client(byID: id)
					)
				}.eraseToAnyAsyncSequence()
			},
			getRequestsFromP2PClientAsyncSequence: { id in
				try await P2PConnections.shared.incomingMessagesAsyncSequence(for: id).map { msg in
					@Dependency(\.jsonDecoder) var jsonDecoder

					let jsonData = msg.messagePayload
					do {
						let requestFromDapp = try jsonDecoder().decode(P2P.FromDapp.Request.self, from: jsonData)
						return try await P2P.RequestFromClient(
							originalMessage: msg,
							requestFromDapp: requestFromDapp,
							client: client(byID: id)
						)
					} catch {
						throw FailedToDecodeRequestFromDappError(
							error: error,
							jsonString: String(data: jsonData, encoding: .utf8) ?? jsonData.hex
						)
					}
				}
				.eraseToAnyAsyncSequence()

			},
			sendMessageReadReceipt: { id, msg in
				try await P2PConnections.shared.sendReceipt(for: id, readMessage: msg)
			},
			sendMessage: { outgoingMsg in
				@Dependency(\.jsonEncoder) var jsonEncoder
				let id = outgoingMsg.connectionID
				let responseToDappData = try jsonEncoder().encode(outgoingMsg.responseToDapp)
				let p2pChannelRequestID = UUID().uuidString
				try await P2PConnections.shared.sendData(for: id, data: responseToDappData, messageID: p2pChannelRequestID)

				for try await receipt in try await P2PConnections.shared.sentReceiptsAsyncSequence(for: id) {
					guard receipt.messageSent.messageID == p2pChannelRequestID else { continue }
					return try await P2P.SentResponseToClient(
						sentReceipt: receipt,
						responseToDapp: outgoingMsg.responseToDapp,
						client: client(byID: id)
					)
				}

				throw FailedToReceiveSentReceiptForSuccessfullyDispatchedMsgToDapp()
			},
			_sendTestMessage: { id, message in
				let msgID = UUID().uuidString
				do {
					try await P2PConnections.shared.sendData(for: id, data: Data(message.utf8), messageID: msgID)
				} catch {
					print("Failed to send test message, error: \(String(describing: error))")
				}
				// does not care about sent message receipts
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

// MARK: - P2PClientNotFoundInProfile
struct P2PClientNotFoundInProfile: LocalizedError {
	init() {}
	var errorDescription: String? {
		L10n.Common.p2PClientNotFoundInProfile
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

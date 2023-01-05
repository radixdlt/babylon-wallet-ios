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

// MARK: - AnyAsyncIterator + Sendable
extension AnyAsyncIterator: @unchecked Sendable where Element: Sendable {}

// MARK: - AnyAsyncSequence + Sendable
extension AnyAsyncSequence: @unchecked Sendable where Element: Sendable {}

// MARK: - AsyncThrowingStream.Iterator + Sendable
extension AsyncThrowingStream.Iterator: @unchecked Sendable where Element: Sendable {}

extension P2P.ClientWithConnectionStatus {
	func connected() -> Self {
		.init(p2pClient: p2pClient, connectionStatus: .connected)
	}
}

extension ProfileClient {
	func p2pClient(for id: P2PConnectionID) async throws -> P2PClient? {
		try await getP2PClients().first(where: { $0.id == id })
	}
}

// MARK: - P2PConnectivityClient + :LiveValue
public extension P2PConnectivityClient {
	static let liveValue: Self = {
		@Dependency(\.profileClient) var profileClient

		let localNetworkAuthorization = LocalNetworkAuthorization()

		@Sendable func client(byID id: P2PClient.ID) async throws -> P2PClient {
			guard let client = try await profileClient.p2pClient(for: id) else {
				throw P2PClientNotFoundInProfile()
			}
			return client
		}

		actor ClientsHolder: GlobalActor {
			typealias Value = OrderedSet<P2PClient>
			private let subject = AsyncCurrentValueSubject<Value>([])
			static let shared = ClientsHolder()
			init() {}

			func emit(_ value: Value) {
				subject.send(value)
			}

			func emit(_ value: P2PClients) {
				emit(OrderedSet(value))
			}

			func clientsAsyncSequence() -> AnyAsyncSequence<Value> {
				subject
					.eraseToAnyAsyncSequence()
			}
		}

		return Self(
			getLocalNetworkAccess: {
				await localNetworkAuthorization.requestAuthorization()
			},
			getP2PClients: {
				let saved = try await profileClient.getP2PClients()
				Task {
					await ClientsHolder.shared.emit(saved)
				}
				Task {
					try await P2PConnections.shared.add(
						connectionsFor: saved,
						autoconnect: true
					)
				}
				return await ClientsHolder.shared.clientsAsyncSequence()
			},
			addP2PClientWithConnection: { client in
				try await profileClient.addP2PClient(client)
				Task {
					try await ClientsHolder.shared.emit(profileClient.getP2PClients())
				}
				_ = try await P2PConnections.shared.add(config: client.config, autoconnect: false)
			},
			deleteP2PClientByID: { id in
				try await profileClient.deleteP2PClientByID(id)
				Task {
					try await ClientsHolder.shared.emit(profileClient.getP2PClients())
				}
				do { try await P2PConnections.shared.removeAndDisconnect(id: id) } catch {
					print("Failed to remove/disconnect client? error: \(error)")
				}
			},
			getConnectionStatusAsyncSequence: { id in
				try await P2PConnections.shared.connectionStatusChangeEventAsyncSequence(for: id).map {
					try await P2P.ClientWithConnectionStatus(
						p2pClient: client(byID: id),
						connectionStatus: $0.connectionStatus
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
			},
			_debugWebsocketStatusAsyncSequence: { id in
				try await P2PConnections.shared.debugWebSocketState(for: id).eraseToAnyAsyncSequence()
			},
			_debugDataChannelStatusAsyncSequence: { id in
				try await P2PConnections.shared.debugDataChannelState(for: id).eraseToAnyAsyncSequence()
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

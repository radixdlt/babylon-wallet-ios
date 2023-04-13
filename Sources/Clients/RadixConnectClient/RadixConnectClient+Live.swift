import CasePaths
import ClientPrelude
import Network
import P2PLinksClient
import RadixConnect

extension RadixConnectClient {
	public static let liveValue: Self = {
		@Dependency(\.p2pLinksClient) var p2pLinksClient

		let rtcClients = RTCClients()
		let localNetworkAuthorization = LocalNetworkAuthorization()

		return Self(
			loadFromProfileAndConnectAll: {
				Task {
					loggerGlobal.info("🔌 Loading and connecting all P2P connections")
					for client in await p2pLinksClient.getP2PLinks() {
						try await rtcClients.connect(
							client.connectionPassword
						)
					}
				}
			},
			disconnectAndRemoveAll: {
				loggerGlobal.info("🔌 Disconnecting and removing all P2P connections")
				await rtcClients.disconnectAndRemoveAll()
				do {
					try await p2pLinksClient.deleteAllP2PLinks()
				} catch {
					loggerGlobal.error("Failed to delete P2PLinks -> \(error)")
				}
			},
			disconnectAll: {
				loggerGlobal.info("🔌 Disconnecting all P2P connections")
				await rtcClients.disconnectAndRemoveAll()
			},
			getLocalNetworkAccess: {
				await localNetworkAuthorization.requestAuthorization()
			},
			getP2PLinks: {
				await OrderedSet(p2pLinksClient.getP2PLinks())
			},
			storeP2PLink: { client in
				try await p2pLinksClient.addP2PLink(client)
			},
			deleteP2PLinkByPassword: { password in
				loggerGlobal.info("Deleting P2P Connection")
				try await p2pLinksClient.deleteP2PLinkByPassword(password)
				await rtcClients.disconnectAndRemoveClient(password)
			},
			addP2PWithPassword: { password in
				try await rtcClients.connect(password, waitsForConnectionToBeEstablished: true)
			},
			receiveMessages: { await rtcClients.incomingMessages() },
			sendResponse: { response, route in
				try await rtcClients.sendResponse(response, to: route)
			},
			sendRequest: { request, strategy in
				try await rtcClients.sendRequest(request, strategy: strategy)
			}
		)
	}()
}

extension AsyncSequence where AsyncIterator: Sendable, Element == P2P.RTCIncomingMessage {
	func filter<Case>(
		_ casePath: CasePath<P2P.RTCMessageFromPeer, Case>
	) async -> AnyAsyncSequence<P2P.RTCIncomingMessageContainer<Case>> {
		compactMap { incomingMessage -> P2P.RTCIncomingMessageContainer<Case>? in
			guard let incomingRequestOrResponse = incomingMessage.flatMap({ (success: P2P.RTCMessageFromPeer) -> Case? in
				casePath.extract(from: success)
			}) else {
				return nil
			}
			return incomingRequestOrResponse
		}
		.share()
		.eraseToAnyAsyncSequence()
	}
}

extension RadixConnectClient {
	public func receiveRequests<Case>(
		_ casePath: CasePath<P2P.RTCMessageFromPeer.Request, Case>
	) async -> AnyAsyncSequence<P2P.RTCIncomingMessageContainer<Case>> {
		await receiveMessages()
			.filter(/P2P.RTCMessageFromPeer.request)
			.compactMap { (incomingRequest: P2P.RTCIncomingMessageContainer<P2P.RTCMessageFromPeer.Request>) -> P2P.RTCIncomingMessageContainer<Case>? in
				incomingRequest.flatMap {
					casePath.extract(from: $0)
				}
			}
			.share()
			.eraseToAnyAsyncSequence()
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

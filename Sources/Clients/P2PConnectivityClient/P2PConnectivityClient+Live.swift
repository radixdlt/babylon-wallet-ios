import ClientPrelude
import Network
import RadixConnect
import P2PClientsClient

// MARK: - P2PConnectivityClient + :LiveValue
extension P2PConnectivityClient {
	public static let liveValue: Self = {
		@Dependency(\.p2pClientsClient) var p2pClientsClient

		let rtcClients = RTCClients(signalingServerBaseURL: .devSignalingServer)
		let localNetworkAuthorization = LocalNetworkAuthorization()

		let loadFromProfileAndConnectAll: LoadFromProfileAndConnectAll = {
			Task {
				print("🔌 Loading and connecting all P2P connections")
				for client in try await p2pClientsClient.getP2PClients() {
					try await rtcClients.addExistingClient(client.connectionPassword)
				}
			}
		}

		return Self(
			loadFromProfileAndConnectAll: loadFromProfileAndConnectAll,
			disconnectAndRemoveAll: {
				print("🔌 Disconnecting and removing all P2P connections")
				await rtcClients.removeAll()
			},
			getLocalNetworkAccess: {
				await localNetworkAuthorization.requestAuthorization()
			},
			getP2PClients: {
				try await OrderedSet(profileClient.getP2PClients())
			},
			storeP2PClient: { client in
				try await profileClient.addP2PClient(client)
			},
			deleteP2PClientByID: { id in
				try await profileClient.deleteP2PClientByID(id)
				await rtcClients.removeClient(id)
			},
			addP2PWithSecrets: { password in
				try await rtcClients.addNewClient(password)
			},
			receiveMessages: { await rtcClients.incommingMessages },
			sendMessage: { outgoingMsg in
				try await rtcClients.sendMessage(outgoingMsg)
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

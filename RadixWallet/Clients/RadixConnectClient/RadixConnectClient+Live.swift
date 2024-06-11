import AsyncAlgorithms
import ComposableArchitecture // actually CasePaths... but CI fails if we do `import CasePaths` 🤷‍♂️
import Network

extension RadixConnectClient {
	public static let liveValue: Self = {
		@Dependency(\.p2pLinksClient) var p2pLinksClient
		@Dependency(\.errorQueue) var errorQueue

		let m2m = Mobile2Mobile()

		@Dependency(\.accountsClient) var accountsClient
		@Dependency(\.jsonEncoder) var jsonEncoder

		let userDefaults = UserDefaults.Dependency.radix // FIXME: find a better way to ensure we use the same userDefaults everywhere

		let rtcClients = RTCClients()
		let localNetworkAuthorization = LocalNetworkAuthorization()

		Task {
			for try await accounts in await accountsClient.accountsOnCurrentNetwork() {
				guard !Task.isCancelled else { return }
				try? await sendAccountListMessage(accounts: accounts)
			}
		}

		Task {
			let connectedClients = await rtcClients.connectClients()
				.filter { updates in
					!updates.flatMap(\.idsOfConnectedPeerConnections).isEmpty
				}
			for try await updates in connectedClients {
				guard !Task.isCancelled else { return }
				sendAccountListMessageAfterConnect()
			}
		}

		@Sendable
		func sendAccountListMessageAfterConnect() {
			Task {
				guard let accounts = try? await accountsClient.getAccountsOnCurrentNetwork() else { return }
				// FIXME: Investigate why this delay is needed. [Slack discussion](https://rdxworks.slack.com/archives/C03QFAWBRNX/p1715583069664349)
				try? await Task.sleep(for: .milliseconds(500))
				try? await sendAccountListMessage(accounts: accounts)
			}
		}

		@Sendable
		func sendAccountListMessage(accounts: Accounts) async throws {
			let encoder = jsonEncoder()
			let accounts = accounts.map {
				WalletInteractionWalletAccount(
					address: $0.address,
					label: $0.displayName,
					appearanceId: $0.appearanceID
				)
			}
			let accountListMessage = P2P.ConnectorExtension.Request.AccountListMessage(
				discriminator: .accountList,
				accounts: accounts
			)

			/// The keys in the JSON will be sorted alphabetically before encoding, ensuring consistent hashing
			encoder.outputFormatting = .sortedKeys

			let accountsHash = try encoder.encode(accountListMessage).hash().hex

			/// Send `AccountListMessage` to CE only if `accountsHash` has changed
			guard userDefaults.getLastSyncedAccountsWithCE() != accountsHash else { return }

			_ = try await rtcClients.sendRequest(.connectorExtension(.accountListMessage(accountListMessage)), strategy: .broadcastToAllPeersWith(purpose: .general))
			userDefaults.setLastSyncedAccountsWithCE(accountsHash)
		}

		let getP2PLinksWithConnectionStatusUpdates: GetP2PLinksWithConnectionStatusUpdates = {
			await rtcClients.connectClients().map { connectedClients in
				let links = await p2pLinksClient.getP2PLinks()
				return connectedClients.compactMap { (clientUpdate: P2P.ClientConnectionsUpdate) -> P2P.LinkConnectionUpdate? in
					guard let link = links.first(where: { $0.clientID == clientUpdate.clientID }) else {
						return nil
					}
					return P2P.LinkConnectionUpdate(
						link: link,
						idsOfConnectedPeerConnections: clientUpdate.idsOfConnectedPeerConnections
					)
				}
			}
			.share()
			.eraseToAnyAsyncSequence()
		}

		let connectToP2PLinks: ConnectToP2PLinks = { links in
			for client in links {
				try await rtcClients.connect(client, isNewConnection: false)
			}
		}

		return Self(
			loadP2PLinksAndConnectAll: {
				Task {
					loggerGlobal.info("🔌 Loading and connecting all P2P connections")
					try await connectToP2PLinks(p2pLinksClient.getP2PLinks())
				}
				return await getP2PLinksWithConnectionStatusUpdates()
			},
			disconnectAll: {
				loggerGlobal.info("🔌 Disconnecting all P2P connections")
				await rtcClients.disconnectAndRemoveAll()
			},
			connectToP2PLinks: connectToP2PLinks,
			getLocalNetworkAccess: {
				await localNetworkAuthorization.requestAuthorization()
			},
			getP2PLinks: {
				await OrderedSet(p2pLinksClient.getP2PLinks())
			},
			getP2PLinksWithConnectionStatusUpdates: getP2PLinksWithConnectionStatusUpdates,
			idsOfConnectedPeerConnections: {
				let connectedClients = await rtcClients.currentlyConnectedClients
				@Dependency(\.p2pLinksClient) var p2pLinksClient

				let links = await p2pLinksClient.getP2PLinks()

				return connectedClients.flatMap { connectedClient -> [PeerConnectionID] in
					guard links.contains(where: { $0.clientID == connectedClient.clientID }) else { return [] }
					return connectedClient.idsOfConnectedPeerConnections
				}
			},
			updateOrAddP2PLink: { client in
				if let oldLink = try await p2pLinksClient.updateOrAddP2PLink(client) {
					await rtcClients.disconnectAndRemoveClient(oldLink.connectionPassword)
				}
			},
			deleteP2PLinkByPassword: { password in
				loggerGlobal.info("Deleting P2P Connection")
				try await p2pLinksClient.deleteP2PLinkByPassword(password)
				await rtcClients.disconnectAndRemoveClient(password)
			},
			connectP2PLink: { p2pLink in
				try await rtcClients.connect(
					p2pLink,
					isNewConnection: true,
					waitsForConnectionToBeEstablished: true
				)

				/// Clear `lastSyncedAccountsWithCE` after a new connection is made, in order to send `AccountListMessage` to CE
				userDefaults.remove(.lastSyncedAccountsWithCE)
			},
			receiveMessages: {
				await AsyncAlgorithms.merge(
					rtcClients.incomingMessages(),
					m2m.incomingMessages()
				)
				.share()
				.eraseToAnyAsyncSequence()
			},
			sendResponse: { response, route in
				switch route {
				case let .deepLink(sessionId):
					try await m2m.sendResponse(response, sessionId: sessionId)
				case let .rtc(route):
					try await rtcClients.sendResponse(response, to: route)
				case .wallet:
					break
				}

			},
			sendRequest: { request, strategy in
				try await rtcClients.sendRequest(request, strategy: strategy)
			},
			handleDappDeepLink: { request in
				do {
					try await m2m.handleRequest(request)
				} catch {
					loggerGlobal.error("Failed to handle deep link \(error)")
					errorQueue.schedule(error)
					throw error
				}
			}
		)
	}()
}

extension AsyncSequence where AsyncIterator: Sendable, Element == P2P.RTCIncomingMessage {
	func compactMap<Case>(
		_ casePath: CasePath<P2P.RTCMessageFromPeer, Case>
	) async -> AnyAsyncSequence<P2P.RTCIncomingMessageContainer<Case>> {
		compactMap { $0.unpackMap(casePath.extract) }
			.share()
			.eraseToAnyAsyncSequence()
	}
}

extension RadixConnectClient {
	public func receiveRequests<Case>(
		_ casePath: CasePath<P2P.RTCMessageFromPeer.Request, Case>
	) async -> AnyAsyncSequence<P2P.RTCIncomingMessageContainer<Case>> {
		await receiveMessages().compactMap(/P2P.RTCMessageFromPeer.request .. casePath)
	}

	public func receiveResponses<Case>(
		_ casePath: CasePath<P2P.RTCMessageFromPeer.Response, Case>
	) async -> AnyAsyncSequence<P2P.RTCIncomingMessageContainer<Case>> {
		await receiveMessages().compactMap(/P2P.RTCMessageFromPeer.response .. casePath)
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
				loggerGlobal.error("\(error.localizedDescription)")
			case let .waiting(error):
				loggerGlobal.error("Local network permission has been denied: \(error)")
				self.reset()
				self.completion?(false)
			@unknown default:
				loggerGlobal.notice("Local network permission unknown state: \(String(describing: newState))")
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
		loggerGlobal.info("Local network permission has been granted")
		completion?(true)
	}
}

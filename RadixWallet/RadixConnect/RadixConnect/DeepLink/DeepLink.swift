import CryptoKit
import Foundation

// MARK: - Mobile2Mobile
public actor Mobile2Mobile {
	let serviceURL = URL(string: "https://radix-connect-relay-dev.rdx-works-main.extratools.works/api/v1")!
	let encryptionScheme = EncryptionScheme.version1
	@Dependency(\.httpClient) var httpClient
	@Dependency(\.openURL) var openURL
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.radixConnectRelay) var radixConnectRelay
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.secureStorageClient) var secureStorageClient
	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.cacheClient) var cacheClient
	@Dependency(\.gatewayAPIClient) var gatewayAPIClient

	private let incomingMessagesSubject: AsyncPassthroughSubject<P2P.RTCIncomingMessage> = .init()

	/// A **multicasted** async sequence for received message from ALL RTCClients.
	public func incomingMessages() async -> AnyAsyncSequence<P2P.RTCIncomingMessage> {
		incomingMessagesSubject.share().eraseToAnyAsyncSequence()
	}

	func handleRequest(_ request: Request) async throws {
		switch request {
		case let .linking(linkingRequest):
			try await linkDapp(linkingRequest)
		case let .request(request):
			try await handleDeepLinkRequest(request)
		}
	}
}

extension Mobile2Mobile {
	func getDappReturnURL(_ dAppOrigin: URL, wellKnownFile: HTTPClient.WellKnownFileResponse) -> URL {
		let callbackPath: String = wellKnownFile.callbackPath ?? "connect"

		return dAppOrigin.appendingPathComponent(callbackPath)
	}

	func getDAppMetadata(_ dappDefinitionAddress: DappDefinitionAddress, origin: URL) async throws -> DappMetadata {
		let ledgerMetadata = try await cacheClient.withCaching(
			cacheEntry: .dAppRequestMetadata(dappDefinitionAddress.address),
			invalidateCached: { (cached: DappMetadata.Ledger) in
				guard
					cached.name != nil,
					cached.description != nil,
					cached.thumbnail != nil
				else {
					/// Some of these fields were not set, fetch and see if they
					/// have been updated since last time...
					return .cachedIsInvalid
				}
				// All relevant fields are set, the cached metadata is valid.
				return .cachedIsValid
			},
			request: {
				let entityMetadataForDapp = try await gatewayAPIClient.getEntityMetadata(dappDefinitionAddress.address, .dappMetadataKeys)
				return try DappMetadata.Ledger(
					entityMetadataForDapp: entityMetadataForDapp,
					dAppDefinintionAddress: dappDefinitionAddress,
					origin: .init(string: origin.absoluteString)!
				)
			}
		)

		return .ledger(ledgerMetadata)
	}

	func fetchWellKnown(dAppOrigin: URL) async throws -> HTTPClient.WellKnownFileResponse {
		try await httpClient.fetchDappWellKnownFile(dAppOrigin)
	}

	func linkDapp(_ request: Request.DappLinking) async throws {
		switch request.origin {
		case let .webDapp(dAppOrigin):
			let dAppPublicKey = request.publicKey

			let wellKnown = await (try? fetchWellKnown(dAppOrigin: dAppOrigin)) ?? HTTPClient.WellKnownFileResponse(dApps: [.init(dAppDefinitionAddress: .wallet)], callbackPath: nil)
			let dappReturnURL = getDappReturnURL(dAppOrigin, wellKnownFile: wellKnown)

			let dAppMetadata: DappMetadata = try await {
				guard let dappDefinitionAddress = wellKnown.dApps.first?.dAppDefinitionAddress else {
					struct MissingDappDefinitionAddress: Error {}
					throw MissingDappDefinitionAddress()
				}

				do {
					return try await getDAppMetadata(dappDefinitionAddress, origin: dAppOrigin)
				} catch {
					if await appPreferencesClient.isDeveloperModeEnabled() {
						return DappMetadata.deepLink(.init(origin: dAppOrigin, dAppDefAddress: dappDefinitionAddress))
					}

					throw error
				}
			}()

			loggerGlobal.critical("Creating the Wallet Private/Public key pair")

			let walletPrivateKey = Curve25519.KeyAgreement.PrivateKey()
			let walletPublicKey = walletPrivateKey.publicKey

			let sharedSecret = try walletPrivateKey.sharedSecretFromKeyAgreement(with: dAppPublicKey)
			let encryptionKey = SymmetricKey(data: sharedSecret.data)

			try secureStorageClient.saveRadixConnectRelaySession(
				.init(
					id: request.sessionId,
					origin: request.origin,
					encryptionKey: .init(hex: encryptionKey.hex)
				)
			)

			let result = await overlayWindowClient.scheduleLinkingDapp(dAppMetadata)

			guard case .primaryButtonTapped = result else {
				return
			}

			let returnURL = dappReturnURL.appending(queryItems: [
				.init(name: "sessionId", value: request.sessionId.rawValue),
				.init(name: "publicKey", value: walletPublicKey.rawRepresentation.hex()),
			])

			switch request.browser.lowercased() {
			case "chrome":
				await openURL(URL(string: returnURL.absoluteString.replacingOccurrences(of: "https://", with: "googlechromes://"))!)
			case "firefox":
				await openURL(URL(string: "firefox://open-url?url=\(returnURL.absoluteString)")!)
			default:
				await openURL(returnURL)
			}
		}
	}

	func sendResponse(
		_ response: P2P.RTCOutgoingMessage.Response,
		sessionId: RadixConnectRelay.Session.ID
	) async throws {
		guard let session = try secureStorageClient.loadRadixConnectRelaySession(sessionId) else {
			return
		}

		try await radixConnectRelay.sendResponse(response, session)
	}

	func handleDeepLinkRequest(_ request: Request.DappRequest) async throws {
		guard let session = try secureStorageClient.loadRadixConnectRelaySession(request.sessionId) else {
			return
		}

		let receivedRequest = try await radixConnectRelay
			.getRequests(session)
			.first {
				switch $0 {
				case let .dapp(dApp):
					dApp.id == .init(rawValue: request.interactionId)
				}
			}

		guard let receivedRequest else {
			return
		}

		incomingMessagesSubject.send(.init(result: .success(.request(receivedRequest)), route: .deepLink(request.sessionId)))
	}
}

extension Mobile2Mobile {
	public enum Request: Sendable {
		case linking(DappLinking)
		case request(DappRequest)

		public struct DappLinking: Sendable {
			public let origin: RadixConnectRelay.Session.Origin
			public let sessionId: RadixConnectRelay.Session.ID
			public let publicKey: Curve25519.KeyAgreement.PublicKey
			public let browser: String
		}

		public struct DappRequest: Sendable {
			public let sessionId: RadixConnectRelay.Session.ID
			public let interactionId: String
		}
	}

	public typealias HandleRequest = (Request) async throws -> Void
}

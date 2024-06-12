import CryptoKit
import Foundation
import SargonUniFFI

// MARK: - Mobile2Mobile
public actor Mobile2Mobile {
	@Dependency(\.httpClient) var httpClient
	@Dependency(\.openURL) var openURL
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.secureStorageClient) var secureStorageClient
	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.cacheClient) var cacheClient
	@Dependency(\.gatewayAPIClient) var gatewayAPIClient

	private let radixConnectMobile = RadixConnectMobile.live(sessionStorage: SecureSessionStorage())

	private let incomingMessagesSubject: AsyncPassthroughSubject<P2P.RTCIncomingMessage> = .init()

	/// A **multicasted** async sequence for received message from ALL RTCClients.
	public func incomingMessages() async -> AnyAsyncSequence<P2P.RTCIncomingMessage> {
		incomingMessagesSubject.share().eraseToAnyAsyncSequence()
	}

	func handleRequest(_ request: RadixConnectMobileConnectRequest) async throws {
		switch request {
		case let .link(linkingRequest):
			try await linkDapp(linkingRequest)
		case let .dappInteraction(request):
			try await handleDeepLinkRequest(request)
		case let .dappInteractionContained(request):
			incomingMessagesSubject.send(.init(result: .success(.request(.dapp(request.request))), route: .deepLink(request.sessionId)))
		}
	}
}

extension Mobile2Mobile {
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

	func linkDapp(_ request: RadixConnectMobileLinkRequest) async throws {
		let dAppOrigin = request.origin
		let wellKnown = await (try? fetchWellKnown(dAppOrigin: dAppOrigin)) ?? HTTPClient.WellKnownFileResponse(dApps: [.init(dAppDefinitionAddress: .wallet)], callbackPath: nil)

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

		let result = await overlayWindowClient.scheduleLinkingDapp(dAppMetadata)

		guard case .primaryButtonTapped = result else {
			return
		}

		let returnURL = try await radixConnectMobile.handleLinkingRequest(request: request, devMode: true)

		switch request.browser.lowercased() {
		case "chrome":
			await openURL(URL(string: returnURL.absoluteString.replacingOccurrences(of: "https://", with: "googlechromes://"))!)
		case "firefox":
			await openURL(URL(string: "firefox://open-url?url=\(returnURL.absoluteString)")!)
		default:
			await openURL(returnURL)
		}
	}

	func sendResponse(
		_ response: P2P.RTCOutgoingMessage.Response,
		sessionId: SessionId
	) async throws {
		switch response {
		case let .dapp(walletToDappInteractionResponse):
			try await radixConnectMobile.sendDappInteractionResponse(
				walletResponse: .init(
					sessionId: sessionId,
					response: walletToDappInteractionResponse
				)
			)
		}
	}

	func handleDeepLinkRequest(_ request: RadixConnectMobileDappRequest) async throws {
		let receivedRequest = try await radixConnectMobile.handleDappInteractionRequest(dappRequest: request)

		incomingMessagesSubject.send(.init(result: .success(.request(.dapp(receivedRequest.interaction))), route: .deepLink(request.sessionId)))
	}
}

// MARK: - SecureSessionStorage
final class SecureSessionStorage: SessionStorage {
	@Dependency(\.secureStorageClient) var secureStorageClient

	func saveSession(sessionId: SessionId, encodedSession: BagOfBytes) async throws {
		try secureStorageClient.saveRadixConnectRelaySession(sessionId, encodedSession)
	}

	func loadSession(sessionId: SessionId) async throws -> BagOfBytes? {
		try secureStorageClient.loadRadixConnectRelaySession(sessionId)
	}
}

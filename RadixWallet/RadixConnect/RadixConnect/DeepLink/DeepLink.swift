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

	func handleRequest(_ request: URL) async throws {
		let result = try await radixConnectMobile.handleDeepLink(url: request.absoluteString)

		if result.originRequiresValidation {
			let dAppOrigin = result.origin
			let wellKnown = await (try? fetchWellKnown(dAppOrigin: result.origin)) ?? HTTPClient.WellKnownFileResponse(dApps: [.init(dAppDefinitionAddress: .wallet)], callbackPath: nil)
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

			let userAction = await overlayWindowClient.scheduleLinkingDapp(dAppMetadata)

			guard case .primaryButtonTapped = userAction else {
				return
			}

			try await radixConnectMobile.requestOriginVerified(sessionId: result.sessionId)
		}

		incomingMessagesSubject.send(.init(result: .success(.request(.dapp(result.interaction))), route: .deepLink(result.sessionId)))
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

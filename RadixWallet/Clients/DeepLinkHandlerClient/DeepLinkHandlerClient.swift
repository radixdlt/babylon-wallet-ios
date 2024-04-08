// MARK: - DeepLinkHandlerClient
public struct DeepLinkHandlerClient: DependencyKey {
	public var handleDeepLink: HandleDeepLink
}

// MARK: DeepLinkHandlerClient.HandleDeepLink
extension DeepLinkHandlerClient {
	public typealias HandleDeepLink = (URL) -> Void
}

extension DeepLinkHandlerClient {
	static let m2mDeepLinkHost = "d1rxdfxrfmemlj.cloudfront.net"

	public enum Error: Swift.Error {
		case emptyQuery
		case missingRequestOrigin
		case missingPublicKey
		case missingSessionId
		case missingDappReturnURL
	}

	public static var liveValue: DeepLinkHandlerClient {
		@Dependency(\.radixConnectClient) var radixConnectClient
		@Dependency(\.errorQueue) var errorQueue

		func extractWalletConnectRequest(_ url: URL) throws -> Mobile2Mobile.Request {
			guard let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems else {
				throw Error.emptyQuery
			}

			guard let sessionId = queryItems.first(where: { $0.name == "sessionId" })?.value else {
				throw Error.missingSessionId
			}

			if let interactionId = queryItems.first(where: { $0.name == "interactionId" })?.value {
				return .request(.init(sessionId: sessionId, interactionId: interactionId))
			}

			guard let publicKey = queryItems.first(where: { $0.name == "publicKey" })?.value
			else {
				throw Error.missingPublicKey
			}

			guard let origin = queryItems.first(where: { $0.name == "origin" })?.value,
			      let oringURL = URL(string: origin)
			else {
				throw Error.missingRequestOrigin
			}

			return .linking(.init(dAppOrigin: oringURL, publicKeyHex: publicKey, sessionId: sessionId))
		}

		return DeepLinkHandlerClient(handleDeepLink: { url in
			if url.host() == m2mDeepLinkHost {
				do {
					let request = try extractWalletConnectRequest(url)
					Task {
						try await radixConnectClient.handleDappDeepLink(request)
					}
				} catch {
					errorQueue.schedule(error)
				}
			} else {
				struct UnknownDeepLinkURL: Swift.Error {}
				errorQueue.schedule(UnknownDeepLinkURL())
			}
		})
	}
}

extension DependencyValues {
	public var deepLinkHandlerClient: DeepLinkHandlerClient {
		get { self[DeepLinkHandlerClient.self] }
		set { self[DeepLinkHandlerClient.self] = newValue }
	}
}

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
		@Dependency(\.mobile2MobileClient) var mobile2MobileClient

		func extractWalletConnectRequest(_ url: URL) throws -> Mobile2MobileClient.WalletConnectRequest {
			guard let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems else {
				throw Error.emptyQuery
			}

			guard let origin = queryItems.first(where: { $0.name == "origin" })?.value,
			      let oringURL = URL(string: origin)
			else {
				throw Error.missingRequestOrigin
			}

			guard let rawPublicKey = queryItems.first(where: { $0.name == "publicKey" })?.value,
			      let publicKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: HexCodable32Bytes(hex: rawPublicKey).data.data)
			else {
				throw Error.missingPublicKey
			}

			guard let rawSessionId = queryItems.first(where: { $0.name == "sessionId" })?.value, let sessionID = UUID(uuidString: rawSessionId) else {
				throw Error.missingSessionId
			}

			return .init(dAppOrigin: oringURL, publicKey: publicKey, sessionId: sessionID)
		}

		return DeepLinkHandlerClient(handleDeepLink: { url in
			if url.host() == m2mDeepLinkHost {
				let request = try! extractWalletConnectRequest(url)
				Task {
					try await mobile2MobileClient.handleRequest(request)
				}
			} else {
				assertionFailure("Unknown deep link url - \(url)")
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

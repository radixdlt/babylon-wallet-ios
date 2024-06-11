import Foundation

// MARK: - DeepLinkHandlerClient
public struct DeepLinkHandlerClient: DependencyKey {
	public var handleDeepLink: HandleDeepLink
	public var addDeepLink: AddDeepLink
	public var hasDeepLink: HasDeepLink
}

// MARK: DeepLinkHandlerClient.HandleDeepLink
extension DeepLinkHandlerClient {
	public typealias HandleDeepLink = () -> Void
	public typealias AddDeepLink = (URL) -> Void
	public typealias HasDeepLink = () -> Bool
}

extension DeepLinkHandlerClient {
	static let m2mDeepLinkHost = "dr6vsuukf8610.cloudfront.net"
	static let deepLinkScheme = "radixwallet"

	public enum Error: LocalizedError {
		case emptyQuery
		case missingRequestOrigin
		case missingPublicKey
		case missingSessionId
		case missingDappReturnURL

		public var errorDescription: String? {
			switch self {
			case .emptyQuery:
				"Empty query"
			case .missingRequestOrigin:
				"missingRequestOrigin"
			case .missingPublicKey:
				"missingPublicKey"
			case .missingSessionId:
				"missingSessionId"
			case .missingDappReturnURL:
				"missingDappReturnURL"
			}
		}
	}

	public static var liveValue: DeepLinkHandlerClient {
		@Dependency(\.radixConnectClient) var radixConnectClient
		@Dependency(\.errorQueue) var errorQueue

		struct State {
			var bufferedDeepLink: URL?
		}

		var state = State()

		func extractWalletConnectRequest(_ url: URL) throws -> Mobile2Mobile.Request {
			guard let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems else {
				throw Error.emptyQuery
			}

			guard let sessionId = queryItems.first(where: { $0.name == "sessionId" })?.value else {
				throw Error.missingSessionId
			}

			if let interactionId = queryItems.first(where: { $0.name == "interactionId" })?.value {
				return .request(.init(sessionId: .init(sessionId), interactionId: interactionId))
			}

			guard let origin = queryItems.first(where: { $0.name == "origin" })?.value,
			      let oringURL = URL(string: origin)
			else {
				throw Error.missingRequestOrigin
			}

			guard let publicKeyItem = queryItems.first(where: { $0.name == "publicKey" })?.value
			else {
				throw Error.missingPublicKey
			}

			let browser = queryItems.first(where: { $0.name == "browser" })?.value ?? "safari"

			let publicKey = try Exactly32Bytes(hex: publicKeyItem)

			return try .linking(.init(origin: .webDapp(oringURL), sessionId: .init(sessionId), publicKey: .init(rawRepresentation: publicKey.data.data), browser: browser))
		}

		return DeepLinkHandlerClient(
			handleDeepLink: {
				if let url = state.bufferedDeepLink {
					state.bufferedDeepLink = nil
					loggerGlobal.error("\(url.absoluteString)")
					if url.host() == m2mDeepLinkHost || url.scheme == deepLinkScheme {
						do {
							let request = try extractWalletConnectRequest(url)
							Task {
								try await radixConnectClient.handleDappDeepLink(request)
							}
						} catch {
							errorQueue.schedule(error)
						}
					} catch {
						errorQueue.schedule(error)
					}
				}
			},
			addDeepLink: {
				state.bufferedDeepLink = $0
			},
			hasDeepLink: {
				state.bufferedDeepLink != nil
			}
		)
	}
}

extension DependencyValues {
	public var deepLinkHandlerClient: DeepLinkHandlerClient {
		get { self[DeepLinkHandlerClient.self] }
		set { self[DeepLinkHandlerClient.self] = newValue }
	}
}

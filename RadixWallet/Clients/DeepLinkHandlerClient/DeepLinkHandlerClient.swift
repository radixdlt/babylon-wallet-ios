import Foundation
import SargonUniFFI

// MARK: - DeepLinkHandlerClient
public struct DeepLinkHandlerClient: Sendable, DependencyKey {
	public var handleDeepLink: HandleDeepLink
	public var setDeepLink: AddDeepLink
	public var hasDeepLink: HasDeepLink
}

// MARK: DeepLinkHandlerClient.HandleDeepLink
extension DeepLinkHandlerClient {
	public typealias HandleDeepLink = () -> Void
	public typealias AddDeepLink = (URL) -> Void
	public typealias HasDeepLink = () -> Bool
}

extension DeepLinkHandlerClient {
	public static var liveValue: DeepLinkHandlerClient {
		@Dependency(\.radixConnectClient) var radixConnectClient
		@Dependency(\.errorQueue) var errorQueue

		struct State {
			var bufferedDeepLink: URL?
		}

		var state = State()

		return DeepLinkHandlerClient(
			handleDeepLink: {
				if let url = state.bufferedDeepLink {
					loggerGlobal.debug("Handling deepLink url \($0.absoluteString)")
					state.bufferedDeepLink = nil
					do {
						Task {
							try await radixConnectClient.handleDappDeepLink(url)
						}
					} catch {
						errorQueue.schedule(error)
					}
				}
			},
			setDeepLink: {
				loggerGlobal.debug("Received deepLink url \($0.absoluteString)")
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

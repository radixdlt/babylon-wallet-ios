// MARK: - DeepLinkHandlerClient
/// A client that manages the handling of the received deepLink.
/// It will delegate the deepLink to the respective subcomponent.
struct DeepLinkHandlerClient: DependencyKey {
	var handleDeepLink: HandleDeepLink
	var setDeepLink: AddDeepLink
	var hasDeepLink: HasDeepLink
}

extension DeepLinkHandlerClient {
	typealias HandleDeepLink = () -> Void
	typealias AddDeepLink = (URL) -> Void
	typealias HasDeepLink = () -> Bool
}

extension DependencyValues {
	var deepLinkHandlerClient: DeepLinkHandlerClient {
		get { self[DeepLinkHandlerClient.self] }
		set { self[DeepLinkHandlerClient.self] = newValue }
	}
}

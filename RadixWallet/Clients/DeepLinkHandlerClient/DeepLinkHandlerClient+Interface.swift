// MARK: - DeepLinkHandlerClient
public struct DeepLinkHandlerClient: DependencyKey {
	public var handleDeepLink: HandleDeepLink
	public var setDeepLink: AddDeepLink
	public var hasDeepLink: HasDeepLink
}

extension DeepLinkHandlerClient {
	public typealias HandleDeepLink = () -> Void
	public typealias AddDeepLink = (URL) -> Void
	public typealias HasDeepLink = () -> Bool
}

extension DependencyValues {
	public var deepLinkHandlerClient: DeepLinkHandlerClient {
		get { self[DeepLinkHandlerClient.self] }
		set { self[DeepLinkHandlerClient.self] = newValue }
	}
}

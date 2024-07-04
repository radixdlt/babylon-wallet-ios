// MARK: - AppEventsClient
public struct AppEventsClient: Sendable {
	public var handleEvent: HandleEvent

	init(handleEvent: @escaping HandleEvent) {
		self.handleEvent = handleEvent
	}
}

// MARK: AppEventsClient.HandleEvent
extension AppEventsClient {
	public typealias HandleEvent = @Sendable (AppEvent) -> Void
}

extension DependencyValues {
	public var appEventsClient: AppEventsClient {
		get { self[AppEventsClient.self] }
		set { self[AppEventsClient.self] = newValue }
	}
}

// MARK: - AppEvent
public enum AppEvent: Sendable, Hashable {
	case appStarted
	case walletCreated
	case deepLinkReceived(String)
}

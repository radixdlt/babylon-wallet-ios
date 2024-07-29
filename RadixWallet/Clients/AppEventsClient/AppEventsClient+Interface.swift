// MARK: - AppEventsClient
public struct AppEventsClient: Sendable {
	public var handleEvent: HandleEvent
	public var events: Events

	init(handleEvent: @escaping HandleEvent, events: @escaping Events) {
		self.handleEvent = handleEvent
		self.events = events
	}
}

// MARK: AppEventsClient.HandleEvent
extension AppEventsClient {
	public typealias HandleEvent = @Sendable (AppEvent) -> Void
	public typealias Events = @Sendable () -> AnyAsyncSequence<AppEvent>
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
	case walletRestored
	case deferredDeepLinkReceived(String)
	case walletDidReset
}

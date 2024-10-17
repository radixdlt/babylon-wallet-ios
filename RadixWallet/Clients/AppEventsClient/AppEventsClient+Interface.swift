// MARK: - AppEventsClient
struct AppEventsClient: Sendable {
	var handleEvent: HandleEvent
	var events: Events

	init(handleEvent: @escaping HandleEvent, events: @escaping Events) {
		self.handleEvent = handleEvent
		self.events = events
	}
}

// MARK: AppEventsClient.HandleEvent
extension AppEventsClient {
	typealias HandleEvent = @Sendable (AppEvent) -> Void
	typealias Events = @Sendable () -> AnyAsyncSequence<AppEvent>
}

extension DependencyValues {
	var appEventsClient: AppEventsClient {
		get { self[AppEventsClient.self] }
		set { self[AppEventsClient.self] = newValue }
	}
}

// MARK: - AppEvent
enum AppEvent: Sendable, Hashable {
	case appStarted
	case walletCreated
	case walletRestored
	case deferredDeepLinkReceived(String)
	case walletDidReset
}

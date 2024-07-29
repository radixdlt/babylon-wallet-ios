// MARK: - AppsFlyerClient
struct AppsFlyerClient: Sendable {
	/// Method to be called once on app start.
	var start: Start

	/// Method to be called every time the `AppDelegate`/`SceneDelegate` is called to continue
	/// with a user activity.
	///
	/// Note: such methods aren't actually called right now on neither of those classes. However, given AppsFlyer documentation
	/// indicates that we should delegate the call to their lib (so that it can resolves deferred deep links), I am adding support for it
	/// in case the situation changes in the future.
	var `continue`: Continue
}

// MARK: AppsFlyerClient.Start
extension AppsFlyerClient {
	typealias Start = @Sendable () -> Void
	typealias Continue = @Sendable (NSUserActivity) -> Void
}

extension DependencyValues {
	var appsFlyerClient: AppsFlyerClient {
		get { self[AppsFlyerClient.self] }
		set { self[AppsFlyerClient.self] = newValue }
	}
}

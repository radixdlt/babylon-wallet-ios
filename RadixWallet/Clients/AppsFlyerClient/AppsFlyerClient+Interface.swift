// MARK: - AppsFlyerClient
struct AppsFlyerClient: Sendable {
	var start: Start
}

// MARK: AppsFlyerClient.Start
extension AppsFlyerClient {
	typealias Start = @Sendable () -> Void
}

extension DependencyValues {
	var appsFlyerClient: AppsFlyerClient {
		get { self[AppsFlyerClient.self] }
		set { self[AppsFlyerClient.self] = newValue }
	}
}

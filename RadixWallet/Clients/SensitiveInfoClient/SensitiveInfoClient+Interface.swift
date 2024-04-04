// MARK: - SensitiveInfoClient
struct SensitiveInfoClient: Sendable {
	var read: Read
}

// MARK: SensitiveInfoClient.Read
extension SensitiveInfoClient {
	typealias Read = @Sendable (_ key: Key) -> String
}

extension DependencyValues {
	var sensitiveInfoClient: SensitiveInfoClient {
		get { self[SensitiveInfoClient.self] }
		set { self[SensitiveInfoClient.self] = newValue }
	}
}

// MARK: - SensitiveInfoClient.Key
extension SensitiveInfoClient {
	enum Key: String {
		case appsFlyerAppId = "APPS_FLYER_APP_ID"
		case appsFlyerDevKey = "APPS_FLYER_DEV_KEY"
	}
}

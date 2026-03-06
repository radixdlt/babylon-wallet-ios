// MARK: - IOSSecurityClient
struct IOSSecurityClient {
	var isJailbroken: IsJailbroken
}

// MARK: IOSSecurityClient.IsJailbroken
extension IOSSecurityClient {
	typealias IsJailbroken = @Sendable () -> Bool
}

extension DependencyValues {
	var iOSSecurityClient: IOSSecurityClient {
		get { self[IOSSecurityClient.self] }
		set { self[IOSSecurityClient.self] = newValue }
	}
}

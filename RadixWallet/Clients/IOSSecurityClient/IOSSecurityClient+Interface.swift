// MARK: - IOSSecurityClient
struct IOSSecurityClient: Sendable {
	var isJailbroken: IsJailbroken

	init(
		isJailbroken: @escaping IsJailbroken
	) {
		self.isJailbroken = isJailbroken
	}
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

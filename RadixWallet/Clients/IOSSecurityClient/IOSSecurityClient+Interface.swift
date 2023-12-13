// MARK: - IOSSecurityClient
public struct IOSSecurityClient: Sendable {
	public var isJailbroken: IsJailbroken

	init(
		isJailbroken: @escaping IsJailbroken
	) {
		self.isJailbroken = isJailbroken
	}
}

// MARK: IOSSecurityClient.IsJailbroken
extension IOSSecurityClient {
	public typealias IsJailbroken = @Sendable () -> Bool
}

extension DependencyValues {
	public var iOSSecurityClient: IOSSecurityClient {
		get { self[IOSSecurityClient.self] }
		set { self[IOSSecurityClient.self] = newValue }
	}
}

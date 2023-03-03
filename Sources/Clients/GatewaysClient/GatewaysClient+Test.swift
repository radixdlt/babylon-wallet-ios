import ClientPrelude

extension DependencyValues {
	public var gatewaysClient: GatewaysClient {
		get { self[GatewaysClient.self] }
		set { self[GatewaysClient.self] = newValue }
	}
}

// MARK: - GatewaysClient + TestDependencyKey
extension GatewaysClient: TestDependencyKey {
	public static let previewValue: Self = .noop

	public static let noop = Self(
		getAllGateways: { .init(rawValue: .init(uniqueElements: [.nebunet]))! },
		getCurrentGateway: { .nebunet },
		addGateway: { _ in },
		changeGateway: { _ in }
	)

	public static let testValue = Self(
		getAllGateways: unimplemented("\(Self.self).getAllGateways"),
		getCurrentGateway: unimplemented("\(Self.self).getCurrentGateway"),
		addGateway: unimplemented("\(Self.self).addGateway"),
		changeGateway: unimplemented("\(Self.self).changeGateway")
	)
}

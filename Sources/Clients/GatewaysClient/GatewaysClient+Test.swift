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
		getCurrentNetworkID: { fatalError() },
		getGatewayAPIEndpointBaseURL: { fatalError() },
		getGateways: { .init(current: .nebunet) },
		addGateway: { _ in },
		changeGateway: { _ in }
	)

	public static let testValue = Self(
		getCurrentNetworkID: unimplemented("\(Self.self).getCurrentNetworkID"),
		getGatewayAPIEndpointBaseURL: unimplemented("\(Self.self).getGatewayAPIEndpointBaseURL"),
		getGateways: unimplemented("\(Self.self).getGateways"),
		addGateway: unimplemented("\(Self.self).addGateway"),
		changeGateway: unimplemented("\(Self.self).changeGateway")
	)
}

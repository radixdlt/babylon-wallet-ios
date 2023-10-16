
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
		currentGatewayValues: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		gatewaysValues: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		getAllGateways: { .init(rawValue: .init(uniqueElements: [.nebunet]))! },
		getCurrentGateway: { .nebunet },
		addGateway: { _ in },
		removeGateway: { _ in },
		changeGateway: { _ in }
	)

	public static let testValue = Self(
		currentGatewayValues: unimplemented("\(Self.self).currentGatewayValues"),
		gatewaysValues: unimplemented("\(Self.self).gatewaysValues"),
		getAllGateways: unimplemented("\(Self.self).getAllGateways"),
		getCurrentGateway: unimplemented("\(Self.self).getCurrentGateway"),
		addGateway: unimplemented("\(Self.self).addGateway"),
		removeGateway: unimplemented("\(Self.self).removeGateway"),
		changeGateway: unimplemented("\(Self.self).changeGateway")
	)
}

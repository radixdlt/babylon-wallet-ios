
extension DependencyValues {
	var gatewaysClient: GatewaysClient {
		get { self[GatewaysClient.self] }
		set { self[GatewaysClient.self] = newValue }
	}
}

// MARK: - GatewaysClient + TestDependencyKey
extension GatewaysClient: TestDependencyKey {
	static let previewValue = Self.noop

	static let testValue = Self(
		currentGatewayValues: unimplemented("\(Self.self).currentGatewayValues"),
		gatewaysValues: unimplemented("\(Self.self).gatewaysValues"),
		getAllGateways: unimplemented("\(Self.self).getAllGateways"),
		getCurrentGateway: unimplemented("\(Self.self).getCurrentGateway"),
		addGateway: unimplemented("\(Self.self).addGateway"),
		removeGateway: unimplemented("\(Self.self).removeGateway"),
		changeGateway: unimplemented("\(Self.self).changeGateway"),
		hasGateway: unimplemented("\(Self.self).hasGateway")
	)

	static let noop = Self(
		currentGatewayValues: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		gatewaysValues: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		getAllGateways: { [.nebunet] },
		getCurrentGateway: { .nebunet },
		addGateway: { _ in },
		removeGateway: { _ in },
		changeGateway: { _ in },
		hasGateway: { _ in false }
	)
}

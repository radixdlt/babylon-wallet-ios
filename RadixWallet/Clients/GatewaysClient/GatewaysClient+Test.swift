
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
		currentGatewayValues: unimplemented("\(Self.self).currentGatewayValues", placeholder: noop.currentGatewayValues),
		gatewaysValues: unimplemented("\(Self.self).gatewaysValues", placeholder: noop.gatewaysValues),
		getAllGateways: unimplemented("\(Self.self).getAllGateways", placeholder: noop.getAllGateways),
		getCurrentGateway: unimplemented("\(Self.self).getCurrentGateway", placeholder: noop.getCurrentGateway),
		addGateway: unimplemented("\(Self.self).addGateway"),
		removeGateway: unimplemented("\(Self.self).removeGateway"),
		changeGateway: unimplemented("\(Self.self).changeGateway"),
		hasGateway: unimplemented("\(Self.self).hasGateway", placeholder: noop.hasGateway)
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

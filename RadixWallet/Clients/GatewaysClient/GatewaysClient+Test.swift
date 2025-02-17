
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
		currentGatewayValues: noop.currentGatewayValues,
		gatewaysValues: noop.gatewaysValues,
		getAllGateways: noop.getAllGateways,
		getCurrentGateway: noop.getCurrentGateway,
		addGateway: unimplemented("\(Self.self).addGateway"),
		removeGateway: unimplemented("\(Self.self).removeGateway"),
		changeGateway: unimplemented("\(Self.self).changeGateway"),
		hasGateway: noop.hasGateway
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

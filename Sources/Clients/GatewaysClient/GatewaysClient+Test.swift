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
		allGateways: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		getAllGateways: { .init(rawValue: .init(uniqueElements: [.nebunet]))! },
		getCurrentGateway: { .nebunet },
		addGateway: { _ in },
		removeGateway: { _ in },
		changeGateway: { _ in }
	)

	public static let testValue = Self(
		allGateways: unimplemented("\(Self.self).allGateways"),
		getAllGateways: unimplemented("\(Self.self).getAllGateways"),
		getCurrentGateway: unimplemented("\(Self.self).getCurrentGateway"),
		addGateway: unimplemented("\(Self.self).addGateway"),
		removeGateway: unimplemented("\(Self.self).removeGateway"),
		changeGateway: unimplemented("\(Self.self).changeGateway")
	)
}

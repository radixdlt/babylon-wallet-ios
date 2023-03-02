import FeaturePrelude

#if DEBUG
extension NetworkSwitchingClient: TestDependencyKey {
	public static let testValue: Self = .init(
		getCurrentGateway: unimplemented("\(Self.self).getCurrentGateway"),
		validateGatewayURL: unimplemented("\(Self.self).validateGatewayURL"),
		hasAccountOnNetwork: unimplemented("\(Self.self).hasAccountOnNetwork"),
		switchTo: unimplemented("\(Self.self).switchTo")
	)
}
#endif

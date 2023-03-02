import FeaturePrelude

#if DEBUG
extension NetworkSwitchingClient: TestDependencyKey {
	public static let testValue: Self = .init(
		getGateway: unimplemented("\(Self.self).getGateway"),
		validateGatewayURL: unimplemented("\(Self.self).validateGatewayURL"),
		hasAccountOnNetwork: unimplemented("\(Self.self).hasAccountOnNetwork"),
		switchTo: unimplemented("\(Self.self).switchTo")
	)
}
#endif

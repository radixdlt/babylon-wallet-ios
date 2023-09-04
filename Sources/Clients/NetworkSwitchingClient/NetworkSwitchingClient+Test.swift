import ClientPrelude

#if DEBUG
extension NetworkSwitchingClient: TestDependencyKey {
	public static let testValue: Self = .init(
		hasMainnetEverBeenLive: unimplemented("\(Self.self).hasMainnetEverBeenLive"),
		getCurrentGateway: unimplemented("\(Self.self).getCurrentGateway"),
		validateGatewayURL: unimplemented("\(Self.self).validateGatewayURL"),
		hasAccountOnNetwork: unimplemented("\(Self.self).hasAccountOnNetwork"),
		switchTo: unimplemented("\(Self.self).switchTo")
	)
}
#endif

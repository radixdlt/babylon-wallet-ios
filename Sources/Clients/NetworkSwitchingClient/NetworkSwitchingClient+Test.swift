import ClientPrelude

#if DEBUG
extension NetworkSwitchingClient: TestDependencyKey {
	public static let testValue: Self = .init(
		isMainnetLive: unimplemented("\(Self.self).isMainnetLive"),
		validateGatewayURL: unimplemented("\(Self.self).validateGatewayURL"),
		hasAccountOnNetwork: unimplemented("\(Self.self).hasAccountOnNetwork"),
		switchTo: unimplemented("\(Self.self).switchTo")
	)
}
#endif

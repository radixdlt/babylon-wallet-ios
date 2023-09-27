import ClientPrelude

#if DEBUG
extension NetworkSwitchingClient: TestDependencyKey {
	public static let testValue: Self = .init(
		validateGatewayURL: unimplemented("\(Self.self).validateGatewayURL"),
		hasAccountOnNetwork: unimplemented("\(Self.self).hasAccountOnNetwork"),
		switchTo: unimplemented("\(Self.self).switchTo")
	)
}
#endif

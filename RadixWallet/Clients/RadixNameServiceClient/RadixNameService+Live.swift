extension RadixNameServiceClient: DependencyKey {
	public typealias Value = RadixNameServiceClient

	public static let liveValue = {
		@Dependency(\.gatewaysClient) var gatewaysClient

		return Self(
			resolveReceiverAccountForDomain: { domain in
				let network = await gatewaysClient.getCurrentNetworkID()

				let rns = try RadixNameService(
					networkingDriver: URLSession.shared,
					networkId: network
				)

				return try await rns.resolveReceiverAccountForDomain(domain: domain)
			}
		)
	}()
}

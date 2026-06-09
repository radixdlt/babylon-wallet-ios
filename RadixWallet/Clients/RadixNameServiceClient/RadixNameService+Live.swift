extension RadixNameServiceClient: DependencyKey {
	public typealias Value = RadixNameServiceClient

	public static let liveValue = {
		@Dependency(\.gatewaysClient) var gatewaysClient

		return Self(
			resolveReceiverAccountForDomain: { domain in
				let gateway = await gatewaysClient.getCurrentGateway()

				let rns = try RadixNameService(
					networkingDriver: URLSession.shared,
					gateway: gateway
				)

				return try await rns.resolveReceiverAccountForDomain(domain: domain)
			}
		)
	}()
}

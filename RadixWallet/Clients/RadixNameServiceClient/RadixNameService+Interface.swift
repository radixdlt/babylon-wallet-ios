// MARK: - RadixNameServiceClient
public struct RadixNameServiceClient: Sendable {
	var resolveReceiverAccountForDomain: ResolveReceiverAccountForDomain
}

extension RadixNameServiceClient {
	typealias ResolveReceiverAccountForDomain = @Sendable (_ domain: RnsDomain) async throws -> RnsDomainConfiguredReceiver
}

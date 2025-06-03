// MARK: - RadixNameServiceClient
public struct RadixNameServiceClient: Sendable {}

extension RadixNameServiceClient {
	typealias ResolveReceiverAccountForDomain = (_ domain: RnsDomain) async throws -> RnsDomainConfiguredReceiver
}

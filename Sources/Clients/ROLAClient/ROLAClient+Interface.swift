import ClientPrelude

// MARK: - ROLAClient
public struct ROLAClient: Sendable, DependencyKey {
	public var performDappDefinitionVerification: PerformDappDefinitionVerification
	public var performWellKnownFileCheck: PerformWellKnownFileCheck
}

// MARK: ROLAClient.PerformWellKnownFileCheck
extension ROLAClient {
	public typealias PerformDappDefinitionVerification = @Sendable (P2P.FromDapp.WalletInteraction) async throws -> Void
	public typealias PerformWellKnownFileCheck = @Sendable (P2P.FromDapp.WalletInteraction) async throws -> Void
}

extension DependencyValues {
	public var rolaClient: ROLAClient {
		get { self[ROLAClient.self] }
		set { self[ROLAClient.self] = newValue }
	}
}

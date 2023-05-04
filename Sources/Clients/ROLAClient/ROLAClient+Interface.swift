import ClientPrelude
import Profile

// MARK: - ROLAClient
public struct ROLAClient: Sendable, DependencyKey {
	public var performDappDefinitionVerification: PerformDappDefinitionVerification
	public var performWellKnownFileCheck: PerformWellKnownFileCheck
	public var createAuthSigningKeyForEntityIfNeeded: CreateAuthSigningKeyForEntityIfNeeded
}

// MARK: ROLAClient.PerformWellKnownFileCheck
extension ROLAClient {
	public typealias PerformDappDefinitionVerification = @Sendable (P2P.Dapp.Request.Metadata) async throws -> Void
	public typealias PerformWellKnownFileCheck = @Sendable (P2P.Dapp.Request.Metadata) async throws -> Void
	public typealias CreateAuthSigningKeyForEntityIfNeeded = @Sendable (CreateAuthSigningKeyForEntityIfNeededRequest) async throws -> Void
}

extension DependencyValues {
	public var rolaClient: ROLAClient {
		get { self[ROLAClient.self] }
		set { self[ROLAClient.self] = newValue }
	}
}

// MARK: - CreateAuthSigningKeyForEntityIfNeededRequest
public struct CreateAuthSigningKeyForEntityIfNeededRequest: Sendable, Hashable {
	public let entityID: WrappedEntityID
	public let networkID: NetworkID
	public init(entityID: WrappedEntityID, networkID: NetworkID) {
		self.entityID = entityID
		self.networkID = networkID
	}

	public init<Entity>(entity: Entity) where Entity: EntityProtocol {
		self.init(entityID: entity.wrappedID, networkID: entity.networkID)
	}
}

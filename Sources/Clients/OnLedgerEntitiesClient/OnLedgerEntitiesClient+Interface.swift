import EngineKit
import Prelude
import SharedModels

// MARK: - OnLedgerEntitiesClient
/// A client that manages loading Entities from the Ledger.
/// Compared to AccountPortfolio it loads the general info about the entities not related to any account.
/// With a refactor, this can potentially also load the Accounts and then link its resources to the general info about resources.
public struct OnLedgerEntitiesClient: Sendable {
	public let getResources: GetResources
	public let getResource: GetResource
	public let getNonFungibleTokenData: GetNonFungibleTokenData
	public let refreshResources: RefreshResources
}

// MARK: - OnLedgerEntitiesClient.GetResources
extension OnLedgerEntitiesClient {
	public typealias GetResources = @Sendable ([ResourceAddress]) async throws -> [OnLedgerEntity.Resource]
	public typealias GetResource = @Sendable (ResourceAddress) async throws -> OnLedgerEntity.Resource
	public typealias GetNonFungibleTokenData = @Sendable (GetNonFungibleTokenDataRequest) async throws -> [OnLedgerEntity.NonFungibleToken]
	public typealias RefreshResources = @Sendable ([ResourceAddress]) async throws -> Void
}

// MARK: OnLedgerEntitiesClient.GetNonFungibleTokenDataRequest
extension OnLedgerEntitiesClient {
	public struct GetNonFungibleTokenDataRequest: Sendable {
		public let atLedgerState: AtLedgerState?
		public let resource: ResourceAddress
		public let nonFungibleIds: [NonFungibleGlobalId]

		public init(
			atLedgerState: AtLedgerState? = nil,
			resource: ResourceAddress,
			nonFungibleIds: [NonFungibleGlobalId]
		) {
			self.atLedgerState = atLedgerState
			self.resource = resource
			self.nonFungibleIds = nonFungibleIds
		}
	}
}

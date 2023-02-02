import ClientPrelude
import Cryptography

public typealias ResourceIdentifier = String

// MARK: - GatewayAPIClient
public struct GatewayAPIClient: Sendable, DependencyKey {
	// MARK: Request
	public var getNetworkName: GetNetworkName
	public var getEpoch: GetEpoch
	public var accountResourcesByAddress: GetAccountResourcesByAddress
	public var accountMetadataByAddress: GetAccountMetadataByAddress
	public var resourcesOverview: GetResourcesOverview
	public var resourceDetailsByResourceIdentifier: GetResourceDetailsByResourceIdentifier
	public var getNonFungibleLocalIds: GetNonFungibleLocalIds
	public var submitTransaction: SubmitTransaction
	public var transactionStatus: GetTransactionStatus
}

public extension GatewayAPIClient {
	typealias GetNetworkName = @Sendable (URL) async throws -> Network.Name

	typealias GetEpoch = @Sendable () async throws -> Epoch

	typealias GetAccountResourcesByAddress = @Sendable (AccountAddress) async throws -> GatewayAPI.EntityResourcesResponse

	typealias GetAccountMetadataByAddress = @Sendable (AccountAddress) async throws -> GatewayAPI.EntityMetadataResponse

	typealias GetResourcesOverview = @Sendable (GatewayAPI.EntityOverviewRequest) async throws -> GatewayAPI.EntityOverviewResponse

	typealias GetResourceDetailsByResourceIdentifier = @Sendable (ResourceIdentifier) async throws -> GatewayAPI.EntityDetailsResponse

	typealias GetNonFungibleLocalIds = @Sendable (AccountAddress, ResourceIdentifier) async throws -> GatewayAPI.NonFungibleLocalIdsResponseAllOf

	typealias SubmitTransaction = @Sendable (GatewayAPI.TransactionSubmitRequest) async throws -> GatewayAPI.TransactionSubmitResponse

	typealias GetTransactionStatus = @Sendable (GatewayAPI.TransactionStatusRequest) async throws -> GatewayAPI.TransactionStatusResponse
}

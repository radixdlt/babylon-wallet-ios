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

extension GatewayAPIClient {
	public typealias GetNetworkName = @Sendable (URL) async throws -> Network.Name

	public typealias GetEpoch = @Sendable () async throws -> Epoch

	public typealias GetAccountResourcesByAddress = @Sendable (AccountAddress) async throws -> GatewayAPI.EntityResourcesResponse

	public typealias GetAccountMetadataByAddress = @Sendable (AccountAddress) async throws -> GatewayAPI.EntityMetadataResponse

	public typealias GetResourcesOverview = @Sendable (GatewayAPI.EntityOverviewRequest) async throws -> GatewayAPI.EntityOverviewResponse

	public typealias GetResourceDetailsByResourceIdentifier = @Sendable (ResourceIdentifier) async throws -> GatewayAPI.EntityDetailsResponse

	public typealias GetNonFungibleLocalIds = @Sendable (AccountAddress, ResourceIdentifier) async throws -> GatewayAPI.NonFungibleIdsResponseAllOf

	public typealias SubmitTransaction = @Sendable (GatewayAPI.TransactionSubmitRequest) async throws -> GatewayAPI.TransactionSubmitResponse

	public typealias GetTransactionStatus = @Sendable (GatewayAPI.TransactionStatusRequest) async throws -> GatewayAPI.TransactionStatusResponse
}

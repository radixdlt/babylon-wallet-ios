import ClientPrelude
import Cryptography

public typealias ResourceIdentifier = String

// MARK: - GatewayAPIClient
public struct GatewayAPIClient: Sendable, DependencyKey {
	// MARK: Request
	public var getNetworkName: GetNetworkName
	public var getEpoch: GetEpoch
	public var accountResourcesByAddress: GetAccountResourcesByAddress
	public var resourcesOverview: GetResourcesOverview
	public var resourceDetailsByResourceIdentifier: GetResourceDetailsByResourceIdentifier
	public var getNonFungibleLocalIds: GetNonFungibleLocalIds
	public var submitTransaction: SubmitTransaction
	public var transactionStatus: GetTransactionStatus
}

extension GatewayAPIClient {
	public typealias GetNetworkName = @Sendable (URL) async throws -> Radix.Network.Name

	public typealias GetEpoch = @Sendable () async throws -> Epoch

	public typealias GetAccountResourcesByAddress = @Sendable (AccountAddress) async throws -> GatewayAPI.StateEntityDetailsResponse

	public typealias GetResourcesOverview = @Sendable (GatewayAPI.StateEntityDetailsRequest) async throws -> GatewayAPI.StateEntityDetailsResponse

	public typealias GetResourceDetailsByResourceIdentifier = @Sendable (ResourceIdentifier) async throws -> GatewayAPI.StateEntityDetailsResponse

	public typealias GetNonFungibleLocalIds = @Sendable (AccountAddress, ResourceIdentifier) async throws -> GatewayAPI.StateNonFungibleIdsResponseAllOf

	public typealias SubmitTransaction = @Sendable (GatewayAPI.TransactionSubmitRequest) async throws -> GatewayAPI.TransactionSubmitResponse

	public typealias GetTransactionStatus = @Sendable (GatewayAPI.TransactionStatusRequest) async throws -> GatewayAPI.TransactionStatusResponse
}

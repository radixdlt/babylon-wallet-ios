import ClientPrelude
import Cryptography

public typealias ResourceIdentifier = String

// MARK: - GatewayAPIClient
public struct GatewayAPIClient: Sendable, DependencyKey {
	// MARK: Request
	public var getNetworkName: GetNetworkName
	public var getEpoch: GetEpoch
	public var getEntityDetails: GetEntityDetails
	public var getAccountDetails: GetAccountDetails
	public var getEntityMetadata: GetEntityMetdata
	public var getNonFungibleIds: GetNonFungibleIds
	public var submitTransaction: SubmitTransaction
	public var transactionStatus: GetTransactionStatus
	public var transactionPreview: TransactionPreview
}

extension GatewayAPIClient {
	public typealias AccountDetailsResponse = SingleEntityDetailsResponse

	public typealias GetNetworkName = @Sendable (URL) async throws -> Radix.Network.Name

	public typealias GetEpoch = @Sendable () async throws -> Epoch

	// MARK: - state/entity

	public typealias GetEntityDetails = @Sendable (_ addresses: [String]) async throws -> GatewayAPI.StateEntityDetailsResponse

	public typealias GetAccountDetails = @Sendable (AccountAddress) async throws -> AccountDetailsResponse

	public typealias GetEntityMetdata = @Sendable (_ address: String) async throws -> GatewayAPI.EntityMetadataCollection

	// MARK: - state/non-fungible
	public typealias GetNonFungibleIds = @Sendable (ResourceIdentifier) async throws -> GatewayAPI.StateNonFungibleIdsResponse

	// MARK: - transaction
	public typealias SubmitTransaction = @Sendable (GatewayAPI.TransactionSubmitRequest) async throws -> GatewayAPI.TransactionSubmitResponse

	public typealias GetTransactionStatus = @Sendable (GatewayAPI.TransactionStatusRequest) async throws -> GatewayAPI.TransactionStatusResponse

	public typealias TransactionPreview = @Sendable (GatewayAPI.TransactionPreviewRequest) async throws -> GatewayAPI.TransactionPreviewResponse
}

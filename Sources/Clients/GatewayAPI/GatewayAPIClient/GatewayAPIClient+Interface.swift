import ClientPrelude
import Cryptography

public typealias ResourceIdentifier = String

// MARK: - GatewayAPIClient
public struct GatewayAPIClient: Sendable, DependencyKey {
	// MARK: Request
	public var getNetworkName: GetNetworkName
	public var getEpoch: GetEpoch
        public var getEntityDetails: GetEntityDetails
        public var getEntityMetadata: GetEntityMetadata
	public var getNonFungibleLocalIds: GetNonFungibleLocalIds
	public var submitTransaction: SubmitTransaction
	public var transactionStatus: GetTransactionStatus
}

extension GatewayAPIClient {
	public typealias GetNetworkName = @Sendable (URL) async throws -> Radix.Network.Name

	public typealias GetEpoch = @Sendable () async throws -> Epoch

        public typealias GetEntityDetails = @Sendable (_ addresses: [String]) async throws -> GatewayAPI.StateEntityDetailsResponse

        public typealias GetEntityMetadata = @Sendable (_ address: String) async throws -> GatewayAPI.StateEntityMetadataPageResponse

	public typealias GetNonFungibleLocalIds = @Sendable (AccountAddress, ResourceIdentifier) async throws -> GatewayAPI.StateEntityNonFungibleIdsPageResponse

	public typealias SubmitTransaction = @Sendable (GatewayAPI.TransactionSubmitRequest) async throws -> GatewayAPI.TransactionSubmitResponse

	public typealias GetTransactionStatus = @Sendable (GatewayAPI.TransactionStatusRequest) async throws -> GatewayAPI.TransactionStatusResponse
}

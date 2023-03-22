import ClientPrelude
import Cryptography

public typealias ResourceIdentifier = String

// MARK: - GatewayAPIClient
public struct GatewayAPIClient: Sendable, DependencyKey {
	// MARK: Request
	public var getNetworkName: GetNetworkName
	public var getEpoch: GetEpoch
	public var getEntityDetails: GetEntityDetails
	public var getNonFungibleIds: GetNonFungibleIds
	public var submitTransaction: SubmitTransaction
	public var transactionStatus: GetTransactionStatus
}

extension GatewayAPIClient {
	public struct EmptyEntityDetailsResponse: Error {}
	public typealias SingleEntityDetailsResponse = (ledgerState: GatewayAPI.LedgerState, details: GatewayAPI.StateEntityDetailsResponseItem)
	public typealias AccountDetailsResponse = SingleEntityDetailsResponse

	public func getAccountDetails(_ accountAddress: AccountAddress) async throws -> AccountDetailsResponse {
		try await getSingleEntityDetails(accountAddress.address)
	}

	public func getEntityMetadata(_ address: String) async throws -> GatewayAPI.EntityMetadataCollection {
		try await getSingleEntityDetails(address).details.metadata
	}

	func getSingleEntityDetails(_ address: String) async throws -> SingleEntityDetailsResponse {
		let response = try await getEntityDetails([address])
		guard let item = response.items.first else {
			throw EmptyEntityDetailsResponse()
		}

		return (response.ledgerState, item)
	}
}

extension GatewayAPIClient {
	public typealias GetNetworkName = @Sendable (URL) async throws -> Radix.Network.Name

	public typealias GetEpoch = @Sendable () async throws -> Epoch

	public typealias GetEntityDetails = @Sendable (_ addresses: [String]) async throws -> GatewayAPI.StateEntityDetailsResponse

	public typealias GetNonFungibleIds = @Sendable (ResourceIdentifier) async throws -> GatewayAPI.StateNonFungibleIdsResponse

	public typealias SubmitTransaction = @Sendable (GatewayAPI.TransactionSubmitRequest) async throws -> GatewayAPI.TransactionSubmitResponse

	public typealias GetTransactionStatus = @Sendable (GatewayAPI.TransactionStatusRequest) async throws -> GatewayAPI.TransactionStatusResponse
}

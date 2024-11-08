import Algorithms
import Sargon

// MARK: - GatewayAPIClient
struct GatewayAPIClient: Sendable, DependencyKey {
	// MARK: Request
	var getNetworkName: GetNetworkName
	var getEpoch: GetEpoch

	// MARK: Entity
	var getEntityDetails: GetEntityDetails
	var getEntityMetadata: GetEntityMetdata
	var getEntityMetadataPage: GetEntityMetdataPage

	// MARK: Fungible Resources
	var getEntityFungiblesPage: GetEntityFungiblesPage
	var getEntityFungibleResourceVaultsPage: GetEntityFungibleResourceVaultsPage

	// MARK: Non-Fungible resources
	var getEntityNonFungiblesPage: GetEntityNonFungiblesPage
	var getEntityNonFungibleResourceVaultsPage: GetEntityNonFungibleResourceVaultsPage
	var getEntityNonFungibleIdsPage: GetEntityNonFungibleIdsPage
	var getNonFungibleData: GetNonFungibleData

	// MARK: Account Lockers
	var getAccountLockerTouchedAt: GetAccountLockerTouchedAt
	var getAccountLockerVaults: GetAccountLockerVaults

	// MARK: Transaction
	var streamTransactions: StreamTransactions
	var prevalidateDeposit: PrevalidateDeposit
}

extension GatewayAPIClient {
	typealias GetNetworkName = @Sendable (URL) async throws -> NetworkDefinition.Name
	typealias GetEpoch = @Sendable () async throws -> Epoch

	// MARK: - Entity
	typealias GetEntityDetails = @Sendable (_ addresses: [String], _ optIns: GatewayAPI.StateEntityDetailsOptIns?, _ ledgerState: GatewayAPI.LedgerStateSelector?) async throws -> GatewayAPI.StateEntityDetailsResponse
	typealias GetEntityMetdata = @Sendable (_ address: String, _ explicitMetadata: Set<EntityMetadataKey>) async throws -> GatewayAPI.EntityMetadataCollection
	typealias GetEntityMetdataPage = @Sendable (GatewayAPI.StateEntityMetadataPageRequest) async throws -> GatewayAPI.StateEntityMetadataPageResponse

	// MARK: - Fungible
	typealias GetEntityFungiblesPage = @Sendable (GatewayAPI.StateEntityFungiblesPageRequest) async throws -> GatewayAPI.StateEntityFungiblesPageResponse
	typealias GetEntityFungibleResourceVaultsPage = @Sendable (GatewayAPI.StateEntityFungibleResourceVaultsPageRequest) async throws -> GatewayAPI.StateEntityFungibleResourceVaultsPageResponse

	// MARK: - NonFungible
	typealias GetEntityNonFungiblesPage = @Sendable (GatewayAPI.StateEntityNonFungiblesPageRequest) async throws -> GatewayAPI.StateEntityNonFungiblesPageResponse
	typealias GetEntityNonFungibleResourceVaultsPage = @Sendable (GatewayAPI.StateEntityNonFungibleResourceVaultsPageRequest) async throws -> GatewayAPI.StateEntityNonFungibleResourceVaultsPageResponse
	typealias GetEntityNonFungibleIdsPage = @Sendable (GatewayAPI.StateEntityNonFungibleIdsPageRequest) async throws -> GatewayAPI.StateEntityNonFungibleIdsPageResponse
	typealias GetNonFungibleData = @Sendable (GatewayAPI.StateNonFungibleDataRequest) async throws -> GatewayAPI.StateNonFungibleDataResponse

	// MARK: - Account Lockers
	typealias GetAccountLockerTouchedAt = @Sendable (GatewayAPI.StateAccountLockersTouchedAtRequest) async throws -> GatewayAPI.StateAccountLockersTouchedAtResponse
	typealias GetAccountLockerVaults = @Sendable (GatewayAPI.StateAccountLockerPageVaultsRequest) async throws -> GatewayAPI.StateAccountLockerPageVaultsResponse

	// MARK: - Transaction
	typealias StreamTransactions = @Sendable (GatewayAPI.StreamTransactionsRequest) async throws -> GatewayAPI.StreamTransactionsResponse
	typealias PrevalidateDeposit = @Sendable (GatewayAPI.AccountDepositPreValidationRequest) async throws -> GatewayAPI.AccountDepositPreValidationResponse
}

extension GatewayAPIClient {
	@Sendable
	func getEntityDetails(_ addresses: [String], _ explicitMetadata: Set<EntityMetadataKey>, _ ledgerState: GatewayAPI.LedgerStateSelector?) async throws -> GatewayAPI.StateEntityDetailsResponse {
		try await getEntityDetails(addresses, .init(explicitMetadata: explicitMetadata.map(\.rawValue)), ledgerState)
	}

	@Sendable
	func getSingleEntityDetails(
		_ address: String,
		explictMetadata: Set<EntityMetadataKey> = []
	) async throws -> GatewayAPI.StateEntityDetailsResponseItem {
		guard let item = try await getEntityDetails([address], explictMetadata, nil).items.first else {
			throw EmptyEntityDetailsResponse()
		}
		return item
	}

	// The maximum number of addresses the `getEntityDetails` can accept
	// This needs to be synchronized with the actual value on the GW side
	static let entityDetailsPageSize = 20

	/// Loads the details for all the addresses provided.
	@Sendable
	func fetchEntitiesDetails(
		_ addresses: [String],
		optIns: GatewayAPI.StateEntityDetailsOptIns,
		selector: GatewayAPI.LedgerStateSelector? = nil
	) async throws -> GatewayAPI.StateEntityDetailsResponse {
		/// gatewayAPIClient.getEntityDetails accepts only `entityDetailsPageSize` addresses for one request.
		/// Thus, chunk the addresses in chunks of `entityDetailsPageSize` and load the details in separate, parallel requests.
		let allResponses = try await addresses
			.chunks(ofCount: GatewayAPIClient.entityDetailsPageSize)
			.map(Array.init)
			.parallelMap {
				try await getEntityDetails($0, optIns, selector)
			}

		guard !allResponses.isEmpty else {
			throw EmptyEntityDetailsResponse()
		}

		// Group multiple GatewayAPI.StateEntityDetailsResponse in one response.
		let allItems = allResponses.flatMap(\.items)
		let ledgerState = allResponses.first!.ledgerState

		return .init(ledgerState: ledgerState, items: allItems)
	}
}

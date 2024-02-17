import Algorithms

public typealias ResourceIdentifier = String

// MARK: - GatewayAPIClient
public struct GatewayAPIClient: Sendable, DependencyKey {
	// MARK: Request
	public var getNetworkName: GetNetworkName
	public var getEpoch: GetEpoch

	// MARK: Entity
	public var getEntityDetails: GetEntityDetails
	public var getEntityMetadata: GetEntityMetdata

	// MARK: Fungible Resources
	public var getEntityFungiblesPage: GetEntityFungiblesPage
	public var getEntityFungibleResourceVaultsPage: GetEntityFungibleResourceVaultsPage

	// MARK: Non-Fungible resources
	public var getEntityNonFungiblesPage: GetEntityNonFungiblesPage
	public var getEntityNonFungibleResourceVaultsPage: GetEntityNonFungibleResourceVaultsPage
	public var getEntityNonFungibleIdsPage: GetEntityNonFungibleIdsPage
	public var getNonFungibleData: GetNonFungibleData

	// MARK: Transaction
	public var submitTransaction: SubmitTransaction
	public var transactionStatus: GetTransactionStatus
	public var transactionPreview: TransactionPreview
	public var streamTransactions: StreamTransactions
}

extension GatewayAPIClient {
	public typealias GetNetworkName = @Sendable (URL) async throws -> Radix.Network.Name
	public typealias GetEpoch = @Sendable () async throws -> Epoch

	// MARK: - Entity
	public typealias GetEntityDetails = @Sendable (_ addresses: [String], _ explicitMetadata: Set<EntityMetadataKey>, _ ledgerState: GatewayAPI.LedgerStateSelector?) async throws -> GatewayAPI.StateEntityDetailsResponse
	public typealias GetEntityMetdata = @Sendable (_ address: String, _ explicitMetadata: Set<EntityMetadataKey>) async throws -> GatewayAPI.EntityMetadataCollection

	// MARK: - Fungible
	public typealias GetEntityFungiblesPage = @Sendable (GatewayAPI.StateEntityFungiblesPageRequest) async throws -> GatewayAPI.StateEntityFungiblesPageResponse
	public typealias GetEntityFungibleResourceVaultsPage = @Sendable (GatewayAPI.StateEntityFungibleResourceVaultsPageRequest) async throws -> GatewayAPI.StateEntityFungibleResourceVaultsPageResponse

	// MARK: - NonFungible
	public typealias GetEntityNonFungiblesPage = @Sendable (GatewayAPI.StateEntityNonFungiblesPageRequest) async throws -> GatewayAPI.StateEntityNonFungiblesPageResponse
	public typealias GetEntityNonFungibleResourceVaultsPage = @Sendable (GatewayAPI.StateEntityNonFungibleResourceVaultsPageRequest) async throws -> GatewayAPI.StateEntityNonFungibleResourceVaultsPageResponse
	public typealias GetEntityNonFungibleIdsPage = @Sendable (GatewayAPI.StateEntityNonFungibleIdsPageRequest) async throws -> GatewayAPI.StateEntityNonFungibleIdsPageResponse
	public typealias GetNonFungibleData = @Sendable (GatewayAPI.StateNonFungibleDataRequest) async throws -> GatewayAPI.StateNonFungibleDataResponse

	// MARK: - Transaction
	public typealias SubmitTransaction = @Sendable (GatewayAPI.TransactionSubmitRequest) async throws -> GatewayAPI.TransactionSubmitResponse
	public typealias GetTransactionStatus = @Sendable (GatewayAPI.TransactionStatusRequest) async throws -> GatewayAPI.TransactionStatusResponse
	public typealias TransactionPreview = @Sendable (GatewayAPI.TransactionPreviewRequest) async throws -> GatewayAPI.TransactionPreviewResponse
	public typealias StreamTransactions = @Sendable (GatewayAPI.StreamTransactionsRequest) async throws -> GatewayAPI.StreamTransactionsResponse
}

extension GatewayAPIClient.TransactionHistoryItem {}

extension GatewayAPIClient {
	public struct TransactionHistoryItem: Sendable, Hashable {
		let time: Date
		let message: String?
		let actions: [Action]
		let manifestType: ManifestType

		enum Action: Sendable, Hashable {
			case deposit(RETDecimal, ResourceBalance)
			case withdrawal(RETDecimal, ResourceBalance)
			case settings
		}

		enum ManifestType {
			case transfer
			case contribute
			case claim
			case depositSettings
			case other
		}
	}

	@Sendable
	public func transactionHistory(account: AccountAddress, cursor: String? = nil) async throws -> [TransactionHistoryItem] {
		let request = GatewayAPI.StreamTransactionsRequest(
			// atLedgerState: GatewayAPI.LedgerStateSelector?,
			// fromLedgerState: GatewayAPI.LedgerStateSelector?,
			cursor: cursor,
			limitPerPage: 100,
			// kindFilter: GatewayAPI.StreamTransactionsRequest.KindFilter?,
			manifestAccountsWithdrawnFromFilter: [account.address],
			manifestAccountsDepositedIntoFilter: [account.address]
			// manifestResourcesFilter: [String]?,
			// affectedGlobalEntitiesFilter: [String]?,
			// eventsFilter: [GatewayAPI.StreamTransactionsRequestEventFilterItem]?,
			// accountsWithManifestOwnerMethodCalls: [String]?,
			// accountsWithoutManifestOwnerMethodCalls: [String]?,
			// manifestClassFilter: <<error type>>,
			// order: GatewayAPI.StreamTransactionsRequest.Order?,
			// optIns: GatewayAPI.TransactionDetailsOptIns(affectedGlobalEntities: true, manifestInstructions: true, balanceChanges: true)
		)

		let response = try await streamTransactions(request)

		func resourceAddresses(for balanceChanges: GatewayAPI.TransactionBalanceChanges) -> [String] {
			balanceChanges.fungibleBalanceChanges.map(\.resourceAddress)
				+ balanceChanges.fungibleFeeBalanceChanges.map(\.resourceAddress)
				+ balanceChanges.nonFungibleBalanceChanges.map(\.resourceAddress)
		}

		let addresses = response.items.flatMap { $0.balanceChanges.map(resourceAddresses) ?? [] }
		let resourceEntityDetails = try await fetchEntitiesDetails(addresses, explicitMetadata: .resourceMetadataKeys)

		var result: [TransactionHistoryItem] = []

		for item in response.items {}

		fatalError()
	}

	/*
	 public private(set) var stateVersion: Int64
	 public private(set) var epoch: Int64
	 public private(set) var round: Int64
	 public private(set) var roundTimestamp: String
	 public private(set) var transactionStatus: TransactionStatus
	 /** Bech32m-encoded hash. */
	 public private(set) var payloadHash: String?
	 /** Bech32m-encoded hash. */
	 public private(set) var intentHash: String?
	 /** String-encoded decimal representing the amount of a related fungible resource. */
	 public private(set) var feePaid: String?
	 public private(set) var affectedGlobalEntities: [String]?
	 public private(set) var confirmedAt: Date?
	 public private(set) var errorMessage: String?
	 /** Hex-encoded binary blob. */
	 public private(set) var rawHex: String?
	 public private(set) var receipt: TransactionReceipt?
	 /** The optional transaction message. This type is defined in the Core API as `TransactionMessage`. See the Core API documentation for more details.  */
	 public private(set) var message: AnyCodable?
	 public private(set) var balanceChanges: TransactionBalanceChanges?
	 */

	@Sendable
	public func getSingleEntityDetails(
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
	public func fetchEntitiesDetails(
		_ addresses: [String],
		explicitMetadata: Set<EntityMetadataKey>,
		selector: GatewayAPI.LedgerStateSelector? = nil
	) async throws -> GatewayAPI.StateEntityDetailsResponse {
		/// gatewayAPIClient.getEntityDetails accepts only `entityDetailsPageSize` addresses for one request.
		/// Thus, chunk the addresses in chunks of `entityDetailsPageSize` and load the details in separate, parallel requests.
		let allResponses = try await addresses
			.chunks(ofCount: GatewayAPIClient.entityDetailsPageSize)
			.map(Array.init)
			.parallelMap {
				try await getEntityDetails($0, explicitMetadata, selector)
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

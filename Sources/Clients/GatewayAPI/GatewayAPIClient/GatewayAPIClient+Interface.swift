import AnyCodable
import ClientPrelude
import Cryptography

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
}

extension GatewayAPIClient {
	public typealias GetNetworkName = @Sendable (URL) async throws -> Radix.Network.Name
	public typealias GetEpoch = @Sendable () async throws -> Epoch

	// MARK: - Entity
	public typealias GetEntityDetails = @Sendable (_ addresses: [String]) async throws -> GatewayAPI.StateEntityDetailsResponse
	public typealias GetEntityMetdata = @Sendable (_ address: String) async throws -> GatewayAPI.EntityMetadataCollection

	// MARK: - Fungible
	public typealias GetEntityFungiblesPage = @Sendable (GatewayAPI.StateEntityFungiblesPageRequest) async throws -> GatewayAPI.StateEntityFungiblesPageResponse
	public typealias GetEntityFungibleResourceVaultsPage = @Sendable (GatewayAPI.StateEntityFungibleResourceVaultsPageRequest) async throws -> GatewayAPI.StateEntityFungibleResourceVaultsPageResponse

	// MARK: - NonFungible
	public typealias GetEntityNonFungiblesPage = @Sendable (GatewayAPI.StateEntityNonFungiblesPageRequest) async throws -> GatewayAPI.StateEntityNonFungiblesPageResponse
	public typealias GetEntityNonFungibleResourceVaultsPage = @Sendable (GatewayAPI.StateEntityNonFungibleResourceVaultsPageRequest) async throws -> GatewayAPI.StateEntityNonFungibleResourceVaultsPageResponse
	public typealias GetEntityNonFungibleIdsPage = @Sendable (GatewayAPI.StateEntityNonFungibleIdsPageRequest) async throws -> GatewayAPI.StateEntityNonFungibleIdsPageResponse
	public typealias GetNonFungibleData = @Sendable (GatewayAPI.StateNonFungibleDataRequest) async throws -> GatewayAPI.StateNonFungibleDataResponse

	// MARK: - transaction

	public typealias SubmitTransaction = @Sendable (GatewayAPI.TransactionSubmitRequest) async throws -> GatewayAPI.TransactionSubmitResponse
	public typealias GetTransactionStatus = @Sendable (GatewayAPI.TransactionStatusRequest) async throws -> GatewayAPI.TransactionStatusResponse
	public typealias TransactionPreview = @Sendable (GatewayAPI.TransactionPreviewRequest) async throws -> GatewayAPI.TransactionPreviewResponse
}

extension GatewayAPIClient {
	public func getDappDefinition(_ address: String) async throws -> GatewayAPI.EntityMetadataCollection {
		print("•• getDappDefinition: \(address)")

		let entityMetadata = try await getEntityMetadata(address)

		print("•• entityMetadata \(address)")

		for item in entityMetadata.items {
			print("\(item.key): \(item.value)")
		}

		guard let dappDefinitionAddress = entityMetadata.dappDefinition else {
			throw GatewayAPI.EntityMetadataCollection.MetadataError.missingDappDefinition
		}

		let dappDefinition = try await getEntityMetadata(dappDefinitionAddress)

		print("•• getDappDefinition \(dappDefinitionAddress)")

		for item in dappDefinition.items {
			print("\(item.key): \(item.value)")
		}

		guard dappDefinition.accountType == .dappDefinition else {
			throw GatewayAPI.EntityMetadataCollection.MetadataError.accountTypeNotDappDefinition
		}

		guard let claimedEntities = dappDefinition.claimedEntities else {
			throw GatewayAPI.EntityMetadataCollection.MetadataError.missingClaimedEntities
		}

		guard claimedEntities.contains(address) else {
			throw GatewayAPI.EntityMetadataCollection.MetadataError.entityNotClaimed
		}

		return dappDefinition
	}
}

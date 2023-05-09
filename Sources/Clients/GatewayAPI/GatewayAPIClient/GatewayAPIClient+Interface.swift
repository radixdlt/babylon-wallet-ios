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

	// MARK: - Transaction

	public typealias SubmitTransaction = @Sendable (GatewayAPI.TransactionSubmitRequest) async throws -> GatewayAPI.TransactionSubmitResponse
	public typealias GetTransactionStatus = @Sendable (GatewayAPI.TransactionStatusRequest) async throws -> GatewayAPI.TransactionStatusResponse
	public typealias TransactionPreview = @Sendable (GatewayAPI.TransactionPreviewRequest) async throws -> GatewayAPI.TransactionPreviewResponse
}

extension GatewayAPIClient {
	/// Extracts the dApp definition from a component, if it has one
	public func getDappDefinition(_ component: ComponentAddress) async throws -> GatewayAPI.EntityMetadataCollection {
		let dappDefinitionAddress = try await getDappDefinitionAddress(component)
		return try await getDappMetadata(dappDefinitionAddress, validating: component)
	}

	/// Extracts the dApp definition address from a component, if one is present
	public func getDappDefinitionAddress(_ component: ComponentAddress) async throws -> DappDefinitionAddress {
		let entityMetadata = try await getEntityMetadata(component.address)

		guard let dappDefinitionAddressString = entityMetadata.dappDefinition else {
			throw GatewayAPI.EntityMetadataCollection.MetadataError.missingDappDefinition
		}

		return try DappDefinitionAddress(address: dappDefinitionAddressString)
	}

	/// Fetches the metadata for a dApp. If the component address is supplied, it validates that it is contained in `claimed_entities`
	public func getDappMetadata(
		_ dappDefinition: DappDefinitionAddress,
		validating component: ComponentAddress? = nil
	) async throws -> GatewayAPI.EntityMetadataCollection {
		let dappDefinition = try await getEntityMetadata(dappDefinition.address)

		guard dappDefinition.accountType == .dappDefinition else {
			throw GatewayAPI.EntityMetadataCollection.MetadataError.accountTypeNotDappDefinition
		}

		if let component {
			guard let claimedEntities = dappDefinition.claimedEntities else {
				throw GatewayAPI.EntityMetadataCollection.MetadataError.missingClaimedEntities
			}
			guard claimedEntities.contains(component.address) else {
				throw GatewayAPI.EntityMetadataCollection.MetadataError.entityNotClaimed
			}
		}

		return dappDefinition
	}
}

import ClientPrelude
import Cryptography
import EngineKit

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
	public typealias GetEntityDetails = @Sendable (_ addresses: [String], _ explicitMetadata: Set<EntityMetadataKey>, _ ledgerState: GatewayAPI.LedgerState?) async throws -> GatewayAPI.StateEntityDetailsResponse
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
}

extension GatewayAPIClient {
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

	/// Extracts the dApp definition from a component, if it has one
	public func getDappDefinition(_ component: ComponentAddress) async throws -> GatewayAPI.EntityMetadataCollection {
		let dappDefinitionAddress = try await getDappDefinitionAddress(component)
		return try await getDappMetadata(dappDefinitionAddress)
			.validating(dAppComponent: component)
	}

	/// Extracts the dApp definition address from a component, if one is present
	public func getDappDefinitionAddress(_ component: ComponentAddress) async throws -> DappDefinitionAddress {
		let entityMetadata = try await getEntityMetadata(component.address, [.dappDefinition])

		guard let dappDefinitionAddressString = entityMetadata.dappDefinition else {
			throw GatewayAPI.EntityMetadataCollection.MetadataError.missingDappDefinition
		}

		return try DappDefinitionAddress(validatingAddress: dappDefinitionAddressString)
	}

	/// Fetches the metadata for a dApp. If the component address is supplied, it validates that it is contained in `claimed_entities`
	public func getDappMetadata(_ dappDefinition: DappDefinitionAddress) async throws -> GatewayAPI.EntityMetadataCollection {
		let dappDefinition = try await getEntityMetadata(dappDefinition.address, [.accountType])

		guard dappDefinition.accountType == .dappDefinition else {
			throw GatewayAPI.EntityMetadataCollection.MetadataError.accountTypeNotDappDefinition
		}

		return dappDefinition
	}

	// The maximum number of addresses the `getEntityDetails` can accept
	// This needs to be synchronized with the actual value on the GW side
	static let entityDetailsPageSize = 20

	/// Loads the details for all the addresses provided.
	@Sendable
	public func fetchResourceDetails(_ addresses: [String], explicitMetadata: Set<EntityMetadataKey>, ledgerState: GatewayAPI.LedgerState? = nil) async throws -> GatewayAPI.StateEntityDetailsResponse {
		/// gatewayAPIClient.getEntityDetails accepts only `entityDetailsPageSize` addresses for one request.
		/// Thus, chunk the addresses in chunks of `entityDetailsPageSize` and load the details in separate, parallel requests.
		let allResponses = try await addresses
			.chunks(ofCount: GatewayAPIClient.entityDetailsPageSize)
			.map(Array.init)
			.parallelMap {
				try await getEntityDetails($0, explicitMetadata, ledgerState)
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

extension GatewayAPI.EntityMetadataCollection {
	public func validating(dAppComponent component: ComponentAddress) throws -> GatewayAPI.EntityMetadataCollection {
		guard let claimedEntities else {
			throw GatewayAPI.EntityMetadataCollection.MetadataError.missingClaimedEntities
		}

		guard claimedEntities.contains(component.address) else {
			throw GatewayAPI.EntityMetadataCollection.MetadataError.entityNotClaimed
		}

		return self
	}

	/// Validate that the entity that owns this metadata gives the provided dAppDefinitionAddress
	public func validating(dAppDefinitionAddress: DappDefinitionAddress) throws -> GatewayAPI.EntityMetadataCollection {
		guard dappDefinition == dAppDefinitionAddress.address else {
			throw GatewayAPI.EntityMetadataCollection.MetadataError.dAppDefinitionNotReciprocating
		}

		return self
	}
}

extension GatewayAPI.RoleKey {
	public var parsedName: ParsedName? {
		.init(rawValue: name)
	}

	public enum ParsedName: String, Hashable {
		case minter
		case burner
		case withdrawer
		case depositor
		case recaller
		case freezer
		case nonFungibleDataUpdater = "non_fungible_data_updater"

		case minterUpdater = "minter_updater"
		case burnerUpdater = "burner_updater"
		case withdrawerUpdater = "withdrawer_updater"
		case depositorUpdater = "depositor_updater"
		case recallerUpdater = "recaller_updater"
		case freezerUpdater = "freezer_updater"
		case nonFungibleDataUpdaterUpdater = "non_fungible_data_updater_updater"
	}
}

extension GatewayAPI.ComponentEntityRoleAssignmentEntry {
	public var parsedAssignment: ParsedAssignment? {
		.init(assignment)
	}

	public enum ParsedAssignment: Hashable {
		case owner
		case denyAll
		case allowAll
		case protected
		case otherExplicit

		init?(_ assignment: GatewayAPI.ComponentEntityRoleAssignmentEntryAssignment) {
			switch assignment.resolution {
			case .owner:
				guard assignment.explicitRule == nil else { return nil }
				self = .owner
			case .explicit:
				guard let explicitRule = assignment.explicitRule?.value as? [String: Any] else { return nil }
				guard let type = explicitRule["type"] as? String else { return nil }
				switch type {
				case "DenyAll":
					self = .denyAll
				case "AllowAll":
					self = .allowAll
				case "Protected":
					self = .protected
				default:
					self = .otherExplicit
				}
			}
		}
	}
}

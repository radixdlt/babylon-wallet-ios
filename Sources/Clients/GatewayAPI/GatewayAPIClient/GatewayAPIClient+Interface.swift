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
	public var getEntityFungibleTokensPage: GetFungibleTokensPageRequest

	public var getEntityMetadataPage: GetEntityMetadataPage

	// MARK: Transaction
	public var submitTransaction: SubmitTransaction
	public var transactionStatus: GetTransactionStatus
	public var transactionPreview: TransactionPreview
}

extension GatewayAPIClient {
	public typealias GetNetworkName = @Sendable (URL) async throws -> Radix.Network.Name

	public typealias GetEpoch = @Sendable () async throws -> Epoch

	// MARK: - state/entity
	public typealias AccountDetailsResponse = SingleEntityDetailsResponse

	public typealias GetEntityDetails = @Sendable (_ addresses: [String]) async throws -> GatewayAPI.StateEntityDetailsResponse

	public typealias GetAccountDetails = @Sendable (AccountAddress) async throws -> AccountDetailsResponse

	public typealias GetEntityMetdata = @Sendable (_ address: String) async throws -> GatewayAPI.EntityMetadataCollection

	public typealias GetEntityMetadataPage = @Sendable (_ request: GatewayAPI.StateEntityMetadataPageRequest) async throws -> GatewayAPI.StateEntityMetadataPageResponse

	// MARK: - state/non-fungible

	public typealias GetNonFungibleIds = @Sendable (ResourceIdentifier) async throws -> GatewayAPI.StateNonFungibleIdsResponse

	public typealias GetFungibleTokensPageRequest = @Sendable (GatewayAPI.StateEntityFungiblesPageRequest) async throws -> GatewayAPI.StateEntityFungiblesPageResponse
	// public typealias GetNonFungibleTokensPageRequest = @Sendable (GatewayAPI.StateEntityNonF) async throws -> GatewayAPI.StateEntityFungiblesPageResponse

	// MARK: - transaction

	public typealias SubmitTransaction = @Sendable (GatewayAPI.TransactionSubmitRequest) async throws -> GatewayAPI.TransactionSubmitResponse

	public typealias GetTransactionStatus = @Sendable (GatewayAPI.TransactionStatusRequest) async throws -> GatewayAPI.TransactionStatusResponse

	public typealias TransactionPreview = @Sendable (GatewayAPI.TransactionPreviewRequest) async throws -> GatewayAPI.TransactionPreviewResponse
}

extension GatewayAPIClient {
	public func getDappDefinition(_ address: String) async throws -> GatewayAPI.EntityMetadataCollection {
		let entityMetadata = try await getEntityMetadata(address)

		guard let dappDefinitionAddress = entityMetadata.dappDefinition else {
			throw GatewayAPI.EntityMetadataCollection.MetadataError.missingDappDefinition
		}

		let dappDefinition = try await getEntityMetadata(dappDefinitionAddress)

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

extension GatewayAPI.EntityMetadataCollection {
	public var description: String? {
		self["description"]?.asString
	}

	public var symbol: String? {
		self["symbol"]?.asString
	}

	public var name: String? {
		self["name"]?.asString
	}

	public var domain: String? {
		self["domain"]?.asString
	}

	public var url: String? {
		self["url"]?.asString
	}

	public var dappDefinition: String? {
		self["dapp_definition"]?.asString
	}

	public var claimedEntities: [String]? {
		self["claimed_entities"]?.asStringCollection
	}

	public var claimedWebsites: [String]? {
		self["claimed_websites"]?.asStringCollection
	}

	public var accountType: AccountType? {
		self["account_type"]?.asString.flatMap(AccountType.init)
	}

	public subscript(key: String) -> GatewayAPI.EntityMetadataItemValue? {
		items.first { $0.key == key }?.value
	}

	public enum AccountType: String {
		case dappDefinition = "dapp definition"
	}

	public enum MetadataError: Error, CustomStringConvertible {
		case missingDappDefinition
		case accountTypeNotDappDefinition
		case missingClaimedEntities
		case entityNotClaimed

		public var description: String {
			switch self {
			case .missingDappDefinition:
				return "The entity has no dApp definition address"
			case .accountTypeNotDappDefinition:
				return "The account is not of the type `dapp definition`"
			case .missingClaimedEntities:
				return "The dapp definition has no claimed_entities key"
			case .entityNotClaimed:
				return "The entity is not claimed by the dapp definition"
			}
		}
	}
}

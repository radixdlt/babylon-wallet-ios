import CacheClient
import EngineKit
import GatewayAPI
import Prelude
import SharedModels

// MARK: - OnLedgerEntitiesClient + DependencyKey
extension OnLedgerEntitiesClient: DependencyKey {
	enum Error: Swift.Error {
		case emptyResponse
	}

	public static let liveValue = Self.live()

	public static func live(
	) -> Self {
		Self(
			getResources: getResources,
			getResource: {
				guard let resource = try await getResources(for: [$0]).first else {
					throw Error.emptyResponse
				}
				return resource
			},
			getNonFungibleTokenData: getNonFungibleData
		)
	}
}

extension AtLedgerState {
	public var selector: GatewayAPI.LedgerStateSelector {
		// TODO: Determine what other fields should be sent
		.init(stateVersion: self.version)
	}
}

extension OnLedgerEntitiesClient {
	@Sendable
	static func getResources(for resources: [ResourceAddress]) async throws -> [OnLedgerEntity.Resource] {
		try await fetchEntitiesWithCaching(
			for: resources.map(\.address),
			refresh: fetchEntites
		)
		.compactMap(\.resource)
	}

	@Sendable
	static func getNonFungibleData(_ request: GetNonFungibleTokenDataRequest) async throws -> [OnLedgerEntity.NonFungibleToken] {
		try await fetchEntitiesWithCaching(
			for: request.nonFungibleIds.map { $0.asStr() },
			refresh: {
				try await fetchNonFungibleData(.init(
					atLedgerState: request.atLedgerState,
					resource: request.resource,
					nonFungibleIds: $0.map { try NonFungibleGlobalId(nonFungibleGlobalId: $0) }
				))
			}
		)
		.compactMap(\.nonFungibleToken)
	}

	static func fetchNonFungibleData(_ request: GetNonFungibleTokenDataRequest) async throws -> [OnLedgerEntity] {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		let response = try await gatewayAPIClient.getNonFungibleData(.init(
			atLedgerState: request.atLedgerState.selector,
			resourceAddress: request.resource.address,
			nonFungibleIds: Array(request.nonFungibleIds.map { try $0.localId().toString() })
		))
		let ledgerState = response.ledgerState

		return try response
			.nonFungibleIds
			.map { item in
				let details = item.details
				let canBeClaimed = details.claimEpoch.map { UInt64(ledgerState.epoch) >= $0 } ?? false
				return try OnLedgerEntity.nonFungibleToken(.init(
					id: .fromParts(
						resourceAddress: .init(address: request.resource.address),
						nonFungibleLocalId: .from(stringFormat: item.nonFungibleId)
					),
					name: details.name,
					description: details.tokenDescription,
					keyImageURL: details.keyImageURL,
					stakeClaimAmount: details.claimAmount,
					canBeClaimed: canBeClaimed
				))
			}
	}

	@Sendable
	static func fetchEntitiesWithCaching(for identifiers: [String], refresh: (_ identifiers: [String]) async throws -> [OnLedgerEntity]) async throws -> [OnLedgerEntity] {
		@Dependency(\.cacheClient) var cacheClient

		let cachedEntities = identifiers.compactMap {
			try? cacheClient.load(OnLedgerEntity.self, .onLedgerEntity(address: $0)) as? OnLedgerEntity
		}

		let notCachedEntities = Set(identifiers).subtracting(Set(cachedEntities.map(\.identifier)))

		guard !notCachedEntities.isEmpty else {
			return cachedEntities
		}

		let freshEntities = try await refresh(Array(notCachedEntities))
		freshEntities.forEach {
			cacheClient.save($0, .onLedgerEntity(address: $0.identifier))
		}

		return cachedEntities + freshEntities
	}

	@Sendable
	static func fetchEntites(for addresses: [String]) async throws -> [OnLedgerEntity] {
		guard !addresses.isEmpty else {
			return []
		}

		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		return try await gatewayAPIClient
			.getEntityDetails(addresses, .resourceMetadataKeys, nil)
			.items
			.compactMap(createEntity)
	}

	@Sendable
	static func createEntity(from item: GatewayAPI.StateEntityDetailsResponseItem) throws -> OnLedgerEntity? {
		let dappDefinitions = item.metadata.dappDefinitions?.compactMap { try? DappDefinitionAddress(validatingAddress: $0) }

		switch item.details {
		case let .fungibleResource(fungibleDetails):
			return try .resource(.init(
				resourceAddress: .init(validatingAddress: item.address),
				divisibility: fungibleDetails.divisibility,
				name: item.explicitMetadata?.name,
				symbol: item.explicitMetadata?.symbol,
				description: item.explicitMetadata?.description,
				iconURL: item.explicitMetadata?.iconURL,
				behaviors: item.details?.fungible?.roleAssignments.extractBehaviors() ?? [],
				tags: item.explicitMetadata?.extractTags() ?? [],
				totalSupply: try? BigDecimal(fromString: fungibleDetails.totalSupply),
				dappDefinitions: dappDefinitions
			))
		case let .nonFungibleResource(nonFungibleDetails):
			return try .resource(.init(
				resourceAddress: .init(validatingAddress: item.address),
				divisibility: nil,
				name: item.explicitMetadata?.name,
				symbol: nil,
				description: item.explicitMetadata?.description,
				iconURL: item.explicitMetadata?.iconURL,
				behaviors: item.details?.nonFungible?.roleAssignments.extractBehaviors() ?? [],
				tags: item.explicitMetadata?.extractTags() ?? [],
				totalSupply: try? BigDecimal(fromString: nonFungibleDetails.totalSupply),
				dappDefinitions: dappDefinitions
			))
		default:
			return nil
		}
	}
}

extension GatewayAPI.EntityMetadataCollection {
	@Sendable public func extractTags() -> [AssetTag] {
		tags?.compactMap(NonEmptyString.init(rawValue:)).map(AssetTag.init) ?? []
	}
}

extension OnLedgerEntity {
	var identifier: String {
		switch self {
		case let .resource(resource):
			return resource.resourceAddress.address
		case let .nonFungibleToken(nonFungibleToken):
			return nonFungibleToken.id.asStr()
		}
	}
}

extension GatewayAPI.StateNonFungibleDetailsResponseItem {
	public typealias NFTData = OnLedgerEntity.NonFungibleToken.NFTData
	public var details: [NFTData] {
		data?.programmaticJson.dictionary?["fields"]?.array?.compactMap {
			guard let dict = $0.dictionary,
			      let value = dict["value"],
			      let type = dict["kind"]?.string.flatMap(GatewayAPI.MetadataValueType.init),
			      let field = dict["field_name"]?.string.flatMap(NFTData.Field.init),
			      let value = NFTData.Value(type: type, value: value)
			else {
				return nil
			}

			return .init(field: field, value: value)
		} ?? []
	}
}

extension OnLedgerEntity.NonFungibleToken.NFTData.Value {
	public init?(type: GatewayAPI.MetadataValueType, value: JSONValue) {
		switch type {
		case .string:
			guard let str = value.string else {
				return nil
			}
			self = .string(str)
		case .url:
			guard let url = value.string.flatMap(URL.init) else {
				return nil
			}
			self = .url(url)
		case .u64:
			guard let u64 = value.string.flatMap(UInt64.init) else {
				return nil
			}
			self = .u64(u64)
		case .decimal:
			guard let decimal = try? value.string.map(BigDecimal.init(fromString:)) else {
				return nil
			}
			self = .decimal(decimal)
		default:
			return nil
		}
	}
}

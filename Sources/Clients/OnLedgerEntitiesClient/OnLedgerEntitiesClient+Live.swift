import CacheClient
import EngineKit
import GatewayAPI
import Prelude
import SharedModels

// MARK: - OnLedgerEntitiesClient + DependencyKey
extension OnLedgerEntitiesClient: DependencyKey {
	public static let maximumNFTIDChunkSize = 29

	enum Error: Swift.Error {
		case emptyResponse
	}

	public static let liveValue = Self.live()

	public static func live() -> Self {
		Self(
			getResources: {
				try await getResources(for: $0)
			},
			getResource: {
				guard let resource = try await getResources(for: [$0], forceRefresh: false).first else {
					throw Error.emptyResponse
				}
				return resource
			},
			getNonFungibleTokenData: getNonFungibleData,
			refreshResources: {
				try await getResources(for: $0, forceRefresh: true)
			},
			getNonFungibleResourceIds: getNonFungibleResourceIds
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
	@discardableResult
	static func getResources(for resources: [ResourceAddress], forceRefresh: Bool = false) async throws -> [OnLedgerEntity.Resource] {
		try await fetchEntitiesWithCaching(
			for: resources.map(\.address),
			forceRefresh: forceRefresh,
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

	@Sendable
	static func getNonFungibleResourceIds(
		_ request: GetNonFungibleResourceIdsRequest
	) async throws -> OnLedgerEntity.AccountNonFungibleIdsPage {
		@Dependency(\.cacheClient) var cacheClient

		let identifier = request.identifier

		let cached = try? cacheClient.load(
			OnLedgerEntity.self,
			.onLedgerEntity(identifier: identifier)
		) as? OnLedgerEntity

		if let cached = cached?.accountNonFungibleIds {
			return cached
		}

		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		let freshPage = try await gatewayAPIClient.getEntityNonFungibleIdsPage(
			.init(
				atLedgerState: request.atLedgerState.selector,
				cursor: request.pageCursor,
				limitPerPage: maximumNFTIDChunkSize,
				address: request.account.address,
				vaultAddress: request.vaultAddress.address,
				resourceAddress: request.resourceAddress.address
			)
		)

		let items = try freshPage.items.map {
			try NonFungibleGlobalId.fromParts(
				resourceAddress: request.resourceAddress.intoEngine(),
				nonFungibleLocalId: .from(stringFormat: $0)
			)
		}

		let response = OnLedgerEntity.AccountNonFungibleIdsPage(ids: items, nextPageCursor: freshPage.nextCursor)
		cacheClient.save(response, .onLedgerEntity(identifier: identifier))
		return response
	}

	static func fetchNonFungibleData(_ request: GetNonFungibleTokenDataRequest) async throws -> [OnLedgerEntity] {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		let response = try await request.nonFungibleIds
			.chunks(ofCount: maximumNFTIDChunkSize)
			.parallelMap { ids in
				try await gatewayAPIClient.getNonFungibleData(.init(
					atLedgerState: request.atLedgerState?.selector,
					resourceAddress: request.resource.address,
					nonFungibleIds: Array(ids.map { try $0.localId().toString() })
				))
			}

		return try response
			.flatMap { item in
				let ledgerState = item.ledgerState
				return try item.nonFungibleIds.map { id in
					let details = id.details
					let canBeClaimed = details.claimEpoch.map { UInt64(ledgerState.epoch) >= $0 } ?? false
					return try OnLedgerEntity.nonFungibleToken(.init(
						id: .fromParts(
							resourceAddress: .init(address: request.resource.address),
							nonFungibleLocalId: .from(stringFormat: id.nonFungibleId)
						),
						data: details
					))
				}
			}
	}

	@Sendable
	static func fetchEntitiesWithCaching(
		for identifiers: [String],
		forceRefresh: Bool = false,
		refresh: (_ identifiers: [String]) async throws -> [OnLedgerEntity]
	) async throws -> [OnLedgerEntity] {
		@Dependency(\.cacheClient) var cacheClient

		if forceRefresh {
			let freshEntities = try await refresh(Array(identifiers))
			freshEntities.forEach {
				cacheClient.save($0, .onLedgerEntity(identifier: $0.identifier))
			}
			return freshEntities
		} else {
			let cachedEntities = identifiers.compactMap {
				try? cacheClient.load(OnLedgerEntity.self, .onLedgerEntity(identifier: $0)) as? OnLedgerEntity
			}

			let notCachedEntities = Set(identifiers).subtracting(Set(cachedEntities.map(\.identifier)))
			guard !notCachedEntities.isEmpty else {
				return cachedEntities
			}

			let freshEntities = try await refresh(Array(notCachedEntities))
			freshEntities.forEach {
				cacheClient.save($0, .onLedgerEntity(identifier: $0.identifier))
			}

			return cachedEntities + freshEntities
		}
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

		let metadata = ResourceMetadata(
			name: item.explicitMetadata?.name,
			symbol: item.explicitMetadata?.symbol,
			description: item.explicitMetadata?.description,
			iconURL: item.explicitMetadata?.iconURL,
			tags: item.explicitMetadata?.extractTags() ?? [],
			dappDefinitions: dappDefinitions
		)

		switch item.details {
		case let .fungibleResource(fungibleDetails):
			return try .resource(.init(
				resourceAddress: .init(validatingAddress: item.address),
				divisibility: fungibleDetails.divisibility,
				behaviors: item.details?.fungible?.roleAssignments.extractBehaviors() ?? [],
				totalSupply: try? RETDecimal(value: fungibleDetails.totalSupply),
				resourceMetadata: metadata
			))
		case let .nonFungibleResource(nonFungibleDetails):
			return try .resource(.init(
				resourceAddress: .init(validatingAddress: item.address),
				divisibility: nil,
				behaviors: item.details?.nonFungible?.roleAssignments.extractBehaviors() ?? [],
				totalSupply: try? RETDecimal(value: nonFungibleDetails.totalSupply),
				resourceMetadata: metadata
			))
		default:
			return nil
		}
	}
}

extension OnLedgerEntity {
	var identifier: String {
		switch self {
		case let .resource(resource):
			return resource.resourceAddress.address
		case let .nonFungibleToken(nonFungibleToken):
			return nonFungibleToken.id.asStr()
		case .accountNonFungibleIds:
			assertionFailure("")
			return "NA"
		}
	}
}

extension OnLedgerEntitiesClient.GetNonFungibleResourceIdsRequest {
	var identifier: String {
		"NonFungibleResourceIds-" + account.address + "-" + resourceAddress.address + (pageCursor.map { "- \($0)" } ?? "")
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
			guard let decimal = try? value.string.map(RETDecimal.init(value:)) else {
				return nil
			}
			self = .decimal(decimal)
		default:
			return nil
		}
	}
}

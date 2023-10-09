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
			getEntities: { addresses, explicitMetadata, ledgerState in
				try await getEntities(for: addresses, explicitMetadata, ledgerState: ledgerState)
			},
			getNonFungibleTokenData: getNonFungibleData,
			getAccountOwnedNonFungibleResourceIds: getNonFungibleResourceIds,
			getAccountOwnedNonFungibleTokenData: getAccountOwnedNonFungibleTokenData
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
	static func getEntities(for addresses: [Address], _ explicitMetadata: Set<EntityMetadataKey>, ledgerState: AtLedgerState?, forceRefresh: Bool = false) async throws -> [OnLedgerEntity] {
		try await fetchEntitiesWithCaching(
			for: addresses.map(\.cachingIdentifier),
			forceRefresh: forceRefresh,
			refresh: fetchEntites(explicitMetadata, ledgerState: ledgerState)
		)
	}

	@Sendable
	static func getNonFungibleData(_ request: GetNonFungibleTokenDataRequest) async throws -> [OnLedgerEntity.NonFungibleToken] {
		try await fetchEntitiesWithCaching(
			for: request.nonFungibleIds.map { .nonFungibleData($0) },
			refresh: { identifiers in
				try await fetchNonFungibleData(.init(
					atLedgerState: request.atLedgerState,
					resource: request.resource,
					nonFungibleIds: identifiers.compactMap {
						if case let .nonFungibleData(id) = $0 {
							return id
						}
						return nil
					}
				))
			}
		)
		.compactMap(\.nonFungibleToken)
	}

	@Sendable
	static func getNonFungibleResourceIds(
		_ request: GetAccountOwnedNonFungibleResourceIdsRequest
	) async throws -> OnLedgerEntity.AccountNonFungibleIdsPage {
		@Dependency(\.cacheClient) var cacheClient

		let cachingIdentifier = CacheClient.Entry.onLedgerEntity(.nonFungibleIdPage(
			request.accountAddress.asGeneral,
			request.resourceAddress.asGeneral,
			request.pageCursor
		))
		let cached = try? cacheClient.load(
			OnLedgerEntity.self,
			cachingIdentifier
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
				address: request.accountAddress.address,
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

		let response = OnLedgerEntity.AccountNonFungibleIdsPage(
			accountAddress: request.accountAddress,
			resourceAddress: request.resourceAddress,
			ids: items,
			pageCursor: request.pageCursor,
			nextPageCursor: freshPage.nextCursor
		)
		cacheClient.save(response, cachingIdentifier)
		return response
	}

	static func getAllNonFungibleResourceIds(_ request: GetAccountOwnedNonFungibleResourceIdsRequest) async throws -> [NonFungibleGlobalId] {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		func collectIds(_ cursor: String?, collectedIds: [NonFungibleGlobalId]) async throws -> [NonFungibleGlobalId] {
			let page = try await getNonFungibleResourceIds(.init(
				account: request.accountAddress,
				resourceAddress: request.resourceAddress,
				vaultAddress: request.vaultAddress,
				atLedgerState: request.atLedgerState,
				pageCursor: cursor
			))

			let ids = collectedIds + page.ids
			guard let nextPageCursor = page.nextPageCursor else {
				return ids
			}
			return try await collectIds(nextPageCursor, collectedIds: collectedIds)
		}

		return try await collectIds(nil, collectedIds: [])
	}

	@Sendable
	static func getAccountOwnedNonFungibleTokenData(_ request: GetAccountOwnedNonFungibleTokenDataRequest) async throws -> [OnLedgerEntity.NonFungibleToken] {
		let ids = try await getAllNonFungibleResourceIds(.init(
			account: request.accountAddress,
			resourceAddress: request.resource.resourceAddress,
			vaultAddress: request.resource.vaultAddress,
			atLedgerState: request.resource.atLedgerState,
			pageCursor: nil
		))
		return try await getNonFungibleData(.init(atLedgerState: request.resource.atLedgerState, resource: request.resource.resourceAddress, nonFungibleIds: ids))
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
		for identifiers: [CacheClient.Entry.OnLedgerEntity],
		forceRefresh: Bool = false,
		refresh: (_ identifiers: [CacheClient.Entry.OnLedgerEntity]) async throws -> [OnLedgerEntity]
	) async throws -> [OnLedgerEntity] {
		@Dependency(\.cacheClient) var cacheClient

		if forceRefresh {
			let freshEntities = try await refresh(Array(identifiers))
			freshEntities.forEach {
				cacheClient.save($0, .onLedgerEntity($0.cachingIdentifier))
			}
			return freshEntities
		} else {
			let cachedEntities = identifiers.compactMap {
				try? cacheClient.load(OnLedgerEntity.self, .onLedgerEntity($0)) as? OnLedgerEntity
			}

			let notCachedEntities = Set(identifiers).subtracting(Set(cachedEntities.map(\.cachingIdentifier)))
			guard !notCachedEntities.isEmpty else {
				return cachedEntities
			}

			let freshEntities = try await refresh(Array(notCachedEntities))
			freshEntities.forEach {
				cacheClient.save($0, .onLedgerEntity($0.cachingIdentifier))
			}

			return cachedEntities + freshEntities
		}
	}

	@Sendable
	static func fetchEntites(
		_ explicitMetadta: Set<EntityMetadataKey>,
		ledgerState: AtLedgerState?
	) -> (_ entities: [CacheClient.Entry.OnLedgerEntity]) async throws -> [OnLedgerEntity] {
		{ entities in
			guard !entities.isEmpty else {
				return []
			}

			@Dependency(\.gatewayAPIClient) var gatewayAPIClient

			let response = try await gatewayAPIClient.getEntityDetails(
				entities.map(\.address.address),
				explicitMetadta,
				ledgerState?.selector
			)
			return try await response.items.asyncCompactMap { item in
				let allFungibles = try await gatewayAPIClient.fetchAllFungibleResources(item, ledgerState: response.ledgerState)
				let allNonFungibles = try await gatewayAPIClient.fetchAllNonFungibleResources(item, ledgerState: response.ledgerState)

				let updatedItem = GatewayAPI.StateEntityDetailsResponseItem(
					address: item.address,
					fungibleResources: .init(items: allFungibles),
					nonFungibleResources: .init(items: allNonFungibles),
					ancestorIdentities: item.ancestorIdentities,
					metadata: item.metadata,
					explicitMetadata: item.explicitMetadata,
					details: item.details
				)

				return try await createEntity(from: updatedItem, ledgerState: .init(version: response.ledgerState.stateVersion, epoch: response.ledgerState.epoch))
			}
		}
	}

	@Sendable
	static func createEntity(from item: GatewayAPI.StateEntityDetailsResponseItem, ledgerState: AtLedgerState) async throws -> OnLedgerEntity? {
		switch item.details {
		case let .fungibleResource(fungibleDetails):
			return try .resource(.init(
				resourceAddress: .init(validatingAddress: item.address),
				atLedgerState: ledgerState,
				divisibility: fungibleDetails.divisibility,
				behaviors: item.details?.fungible?.roleAssignments.extractBehaviors() ?? [],
				totalSupply: try? RETDecimal(value: fungibleDetails.totalSupply),
				metadata: .init(item.explicitMetadata)
			))
		case let .nonFungibleResource(nonFungibleDetails):
			return try .resource(.init(
				resourceAddress: .init(validatingAddress: item.address),
				atLedgerState: ledgerState,
				divisibility: nil,
				behaviors: item.details?.nonFungible?.roleAssignments.extractBehaviors() ?? [],
				totalSupply: try? RETDecimal(value: nonFungibleDetails.totalSupply),
				metadata: .init(item.explicitMetadata)
			))
		default:
			if let accountAddress = try? AccountAddress(validatingAddress: item.address) {
				// create account
				return try await .account(createAccount(
					item,
					accountAddress: accountAddress,
					ledgerState: ledgerState
				))
			} else if let resourcePoolAddress = try? ResourcePoolAddress(validatingAddress: item.address) {
				guard let resourcePool = try await createResourcePool(item, resourcePoolAddress: resourcePoolAddress, ledgerState: ledgerState) else {
					return nil
				}

				return .resourcePool(resourcePool)
			} else if let validatorAddress = try? ValidatorAddress(validatingAddress: item.address) {
				guard let validator = try await createValidator(item, validatorAddress: validatorAddress, ledgerState: ledgerState) else {
					return nil
				}
				return .validator(validator)
			}
			return nil
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
			guard let decimal = try? value.string.map(RETDecimal.init(value:)) else {
				return nil
			}
			self = .decimal(decimal)
		default:
			return nil
		}
	}
}

extension OnLedgerEntity {
	var cachingIdentifier: CacheClient.Entry.OnLedgerEntity {
		switch self {
		case let .resource(resource):
			return .resource(resource.resourceAddress.asGeneral)
		case let .nonFungibleToken(nonFungibleToken):
			return .nonFungibleData(nonFungibleToken.id)
		case let .accountNonFungibleIds(idsPage):
			return .nonFungibleIdPage(idsPage.accountAddress.asGeneral, idsPage.resourceAddress.asGeneral, idsPage.pageCursor)
		case let .account(account):
			return .account(account.address.asGeneral)
		case let .resourcePool(resourcePool):
			return .resourcePool(resourcePool.address.asGeneral)
		case let .validator(validator):
			return .validator(validator.address.asGeneral)
		case let .genericComponent(component):
			return .genericComponent(component.address.asGeneral)
		}
	}
}

extension CacheClient.Entry.OnLedgerEntity {
	var address: Address {
		switch self {
		case let .resource(resource):
			return resource.asGeneral
		case let .account(account):
			return account.asGeneral
		case let .resourcePool(resourcePool):
			return resourcePool.asGeneral
		case let .validator(validator):
			return validator.asGeneral
		case let .genericComponent(genericComponent):
			return genericComponent.asGeneral
		case let .nonFungibleData(nonFungibleId):
			return .init(address: nonFungibleId.resourceAddress().asStr(), decodedKind: .globalNonFungibleResourceManager)
		case let .nonFungibleIdPage(_, resourceAddress, _):
			return resourceAddress.asGeneral
		}
	}
}

extension Address {
	var cachingIdentifier: CacheClient.Entry.OnLedgerEntity {
		switch self.decodedKind {
		case _ where AccountEntityType.addressSpace.contains(self.decodedKind):
			return .account(self)
		case _ where ResourceEntityType.addressSpace.contains(self.decodedKind):
			return .resource(self)
		case _ where ResourcePoolEntityType.addressSpace.contains(self.decodedKind):
			return .resourcePool(self)
		case _ where ValidatorEntityType.addressSpace.contains(self.decodedKind):
			return .validator(self)
		case _ where ComponentEntityType.addressSpace.contains(self.decodedKind):
			return .genericComponent(self)
		default:
			return .genericComponent(self)
		}
	}
}

extension OnLedgerEntity.Account.PoolUnitResources {
	// The fungible resources used to build up the pool units.
	// Will be used to filter out those from the general fungible resources list.
	var fungibleResourceAddresses: [String] {
		radixNetworkStakes.compactMap(\.stakeUnitResource?.resourceAddress.address) +
			poolUnits.map(\.resource.resourceAddress.address)
	}

	// The non fungible resources used to build up the pool units.
	// Will be used to filter out those from the general fungible resources list.
	var nonFungibleResourceAddresses: [String] {
		radixNetworkStakes.compactMap(\.stakeClaimResource?.resourceAddress.address)
	}
}

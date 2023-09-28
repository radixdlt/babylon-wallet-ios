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
			}
		)
	}
}

extension OnLedgerEntitiesClient {
	@Sendable
	static func getResources(for resources: [ResourceAddress]) async throws -> [OnLedgerEntity.Resource] {
		try await fetchEntitiesWithCaching(for: resources.map { $0.asGeneral() }).compactMap(\.resource)
	}

	@Sendable
	static func fetchEntitiesWithCaching(for addresses: [Address]) async throws -> [OnLedgerEntity] {
		@Dependency(\.cacheClient) var cacheClient

		let cachedEntities = addresses.compactMap {
			try? cacheClient.load(OnLedgerEntity.self, .onLedgerEntity(address: $0.address)) as? OnLedgerEntity
		}

		let notCachedEntities = Set(addresses).subtracting(Set(cachedEntities.map(\.address)))

		guard !notCachedEntities.isEmpty else {
			return cachedEntities
		}

		let freshEntities = try await OnLedgerEntitiesClient.fetchEntites(for: Array(notCachedEntities))
		freshEntities.forEach {
			cacheClient.save($0, .onLedgerEntity(address: $0.address.address))
		}

		return cachedEntities + freshEntities
	}

	@Sendable
	static func fetchEntites(for addresses: [Address]) async throws -> [OnLedgerEntity] {
		guard !addresses.isEmpty else {
			return []
		}

		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		return try await gatewayAPIClient
			.getEntityDetails(addresses.map(\.address), .resourceMetadataKeys, nil)
			.items
			.compactMap(createEntity)
	}

	@Sendable
	static func createEntity(from item: GatewayAPI.StateEntityDetailsResponseItem) throws -> OnLedgerEntity? {
		let dappDefinitions = item.explicitMetadata?.dappDefinitions?.compactMap { try? DappDefinitionAddress(validatingAddress: $0) }

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
				totalSupply: try? RETDecimal(value: fungibleDetails.totalSupply),
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
				totalSupply: try? RETDecimal(value: nonFungibleDetails.totalSupply),
				dappDefinitions: dappDefinitions
			))
		default:
			return nil
		}
	}
}

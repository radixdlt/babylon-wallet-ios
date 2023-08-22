import CacheClient
import EngineKit
import GatewayAPI
import Prelude
import SharedModels

// MARK: - OnLedgerEntitiesClient + DependencyKey
extension OnLedgerEntitiesClient: DependencyKey {
	public static let liveValue = Self.live()

	public static func live(
	) -> Self {
		Self(
			getResources: getResources,
			getResource: {
				try await getResources(for: [$0]).first!
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
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		let details = try await gatewayAPIClient.getEntityDetails(addresses.map(\.address), .resourceMetadataKeys, nil)
		return try details.items.compactMap {
			switch $0.details {
			case let .fungibleResource(fungibleDetails):
				return try .resource(.init(
					resourceAddress: .init(validatingAddress: $0.address),
					divisibility: fungibleDetails.divisibility,
					name: $0.explicitMetadata?.name,
					symbol: $0.explicitMetadata?.symbol,
					description: $0.explicitMetadata?.description,
					iconURL: $0.explicitMetadata?.iconURL,
					behaviors: [],
					tags: $0.extractTags(),
					totalSupply: try? BigDecimal(fromString: fungibleDetails.totalSupply)
				))
			case let .nonFungibleResource(nonFungibleDetails):
				return try .resource(.init(
					resourceAddress: .init(validatingAddress: $0.address),
					divisibility: nil,
					name: $0.explicitMetadata?.name,
					symbol: nil,
					description: $0.explicitMetadata?.description,
					iconURL: $0.explicitMetadata?.iconURL,
					behaviors: [],
					tags: $0.extractTags(),
					totalSupply: try? BigDecimal(fromString: nonFungibleDetails.totalSupply)
				))
			default:
				return nil
			}
		}
	}
}

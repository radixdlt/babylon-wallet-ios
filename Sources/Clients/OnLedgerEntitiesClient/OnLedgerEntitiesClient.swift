import CacheClient
import EngineKit
import Foundation
import GatewayAPI
import Prelude
import SharedModels

// MARK: - OnLedgerEntitiesClient
public struct OnLedgerEntitiesClient {
	public let getResources: GetResources
	public let getResource: GetResource
}

// MARK: - OnLedgerResource
public enum OnLedgerResource: Sendable, Hashable {
	case fungible(FungibleResource)
	case nonFungible(NonFungibleResource)

	public var resourceAddress: ResourceAddress {
		switch self {
		case let .fungible(fungible):
			return fungible.resourceAddress
		case let .nonFungible(nonFungible):
			return nonFungible.resourceAddress
		}
	}
}

// MARK: - OnLedgerEntitiesClient.GetResources
extension OnLedgerEntitiesClient {
	public typealias GetResources = @Sendable ([ResourceAddress]) async throws -> [OnLedgerResource]
	public typealias GetResource = @Sendable (ResourceAddress) async throws -> OnLedgerResource
}

extension DependencyValues {
	public var onLedgerEntitiesClient: OnLedgerEntitiesClient {
		get { self[OnLedgerEntitiesClient.self] }
		set { self[OnLedgerEntitiesClient.self] = newValue }
	}
}

// MARK: - OnLedgerEntitiesClient + DependencyKey
extension OnLedgerEntitiesClient: DependencyKey {
	public static let liveValue = Self.live()

	public static func live(
	) -> Self {
		@Dependency(\.cacheClient) var cacheClient

		return Self(
			getResources: { resources in
				try await fetchEntities(resources)
			},
			getResource: {
				try await fetchEntities([$0]).first!
			}
		)
	}
}

extension OnLedgerEntitiesClient {
	static var fetchEntities: GetResources = { resources in
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		let details = try await gatewayAPIClient.getEntityDetails(resources.map(\.address), [], nil)
		return try details.items.compactMap {
			switch $0.details {
			case let .fungibleResource(fungibleDetails):
				return try .fungible(.init(
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
				return try .nonFungible(.init(
					resourceAddress: .init(validatingAddress: $0.address),
					name: $0.explicitMetadata?.name,
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

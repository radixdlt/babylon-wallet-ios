import EngineKit
import Foundation
import Prelude

// MARK: - OnLedgerEntity
public enum OnLedgerEntity: Sendable, Hashable, Codable {
	case resource(Resource)

	public var address: Address {
		switch self {
		case let .resource(resource):
			return resource.resourceAddress.asGeneral()
		}
	}

	public var resource: Resource? {
		guard case let .resource(resource) = self else {
			return nil
		}
		return resource
	}
}

// MARK: OnLedgerEntity.Resource
extension OnLedgerEntity {
	public struct Resource: Sendable, Hashable, Codable, Identifiable {
		public var id: ResourceAddress { resourceAddress }
		public let resourceAddress: ResourceAddress
		public let divisibility: Int?
		public let name: String?
		public let symbol: String?
		public let description: String?
		public let iconURL: URL?
		public let behaviors: [AssetBehavior]
		public let tags: [AssetTag]
		public let totalSupply: BigDecimal?
		public let dappDefinitions: [DappDefinitionAddress]?

		public var fungibility: Fungibility {
			if case .globalFungibleResourceManager = resourceAddress.decodedKind {
				return .fungible
			} else {
				return .nonFungible
			}
		}

		public enum Fungibility {
			case fungible
			case nonFungible
		}

		public init(
			resourceAddress: ResourceAddress,
			divisibility: Int? = nil,
			name: String? = nil,
			symbol: String? = nil,
			description: String? = nil,
			iconURL: URL? = nil,
			behaviors: [AssetBehavior] = [],
			tags: [AssetTag] = [],
			totalSupply: BigDecimal? = nil,
			dappDefinitions: [DappDefinitionAddress]? = nil
		) {
			self.resourceAddress = resourceAddress
			self.divisibility = divisibility
			self.name = name
			self.symbol = symbol
			self.description = description
			self.iconURL = iconURL
			self.behaviors = behaviors
			self.tags = tags
			self.totalSupply = totalSupply
			self.dappDefinitions = dappDefinitions
		}
	}
}

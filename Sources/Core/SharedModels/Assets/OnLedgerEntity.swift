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
	public struct Resource: Sendable, Hashable, Codable {
		public let resourceAddress: ResourceAddress
		public let divisibility: Int?
		public let name: String?
		public let symbol: String?
		public let description: String?
		public let iconURL: URL?
		public let behaviors: [AssetBehavior]
		public let tags: [AssetTag]
		public let totalSupply: BigDecimal?

		public init(
			resourceAddress: ResourceAddress,
			divisibility: Int?,
			name: String?,
			symbol: String?,
			description: String?,
			iconURL: URL?,
			behaviors: [AssetBehavior],
			tags: [AssetTag],
			totalSupply: BigDecimal?
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
		}
	}
}

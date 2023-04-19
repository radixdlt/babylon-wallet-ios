import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.ValidatorCollectionItem")
public typealias ValidatorCollectionItem = GatewayAPI.ValidatorCollectionItem

// MARK: - GatewayAPI.ValidatorCollectionItem
extension GatewayAPI {
	public struct ValidatorCollectionItem: Codable, Hashable {
		/** Bech32m-encoded human readable version of the entity's global address or hex-encoded id. */
		public private(set) var address: String
		public private(set) var state: AnyCodable?
		/** String-encoded decimal representing the amount of a related fungible resource. */
		public private(set) var currentStake: String
		public private(set) var activeInEpoch: ValidatorCollectionItemActiveInEpoch?
		public private(set) var metadata: EntityMetadataCollection

		public init(address: String, state: AnyCodable? = nil, currentStake: String, activeInEpoch: ValidatorCollectionItemActiveInEpoch? = nil, metadata: EntityMetadataCollection) {
			self.address = address
			self.state = state
			self.currentStake = currentStake
			self.activeInEpoch = activeInEpoch
			self.metadata = metadata
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case address
			case state
			case currentStake = "current_stake"
			case activeInEpoch = "active_in_epoch"
			case metadata
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(address, forKey: .address)
			try container.encodeIfPresent(state, forKey: .state)
			try container.encode(currentStake, forKey: .currentStake)
			try container.encodeIfPresent(activeInEpoch, forKey: .activeInEpoch)
			try container.encode(metadata, forKey: .metadata)
		}
	}
}

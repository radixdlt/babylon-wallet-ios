import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.ValidatorCollectionItemActiveInEpoch")
public typealias ValidatorCollectionItemActiveInEpoch = GatewayAPI.ValidatorCollectionItemActiveInEpoch

// MARK: - GatewayAPI.ValidatorCollectionItemActiveInEpoch
extension GatewayAPI {
	public struct ValidatorCollectionItemActiveInEpoch: Codable, Hashable {
		/** String-encoded decimal representing the amount of a related fungible resource. */
		public private(set) var stake: String
		public private(set) var stakePercentage: Double
		public private(set) var key: PublicKey

		public init(stake: String, stakePercentage: Double, key: PublicKey) {
			self.stake = stake
			self.stakePercentage = stakePercentage
			self.key = key
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case stake
			case stakePercentage = "stake_percentage"
			case key
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(stake, forKey: .stake)
			try container.encode(stakePercentage, forKey: .stakePercentage)
			try container.encode(key, forKey: .key)
		}
	}
}

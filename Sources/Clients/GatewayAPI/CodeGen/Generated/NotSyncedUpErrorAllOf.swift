import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.NotSyncedUpErrorAllOf")
public typealias NotSyncedUpErrorAllOf = GatewayAPI.NotSyncedUpErrorAllOf

// MARK: - GatewayAPI.NotSyncedUpErrorAllOf
extension GatewayAPI {
	public struct NotSyncedUpErrorAllOf: Codable, Hashable {
		/** The request type that triggered this exception. */
		public private(set) var requestType: String
		/** The current delay between the Gateway DB and the network ledger round timestamp. */
		public private(set) var currentSyncDelaySeconds: Int64
		/** The maximum allowed delay between the Gateway DB and the network ledger round timestamp for this `request_type`. */
		public private(set) var maxAllowedSyncDelaySeconds: Int64

		public init(requestType: String, currentSyncDelaySeconds: Int64, maxAllowedSyncDelaySeconds: Int64) {
			self.requestType = requestType
			self.currentSyncDelaySeconds = currentSyncDelaySeconds
			self.maxAllowedSyncDelaySeconds = maxAllowedSyncDelaySeconds
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case requestType = "request_type"
			case currentSyncDelaySeconds = "current_sync_delay_seconds"
			case maxAllowedSyncDelaySeconds = "max_allowed_sync_delay_seconds"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(requestType, forKey: .requestType)
			try container.encode(currentSyncDelaySeconds, forKey: .currentSyncDelaySeconds)
			try container.encode(maxAllowedSyncDelaySeconds, forKey: .maxAllowedSyncDelaySeconds)
		}
	}
}

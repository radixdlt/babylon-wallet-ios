import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.ResourceAggregationLevel")
public typealias ResourceAggregationLevel = GatewayAPI.ResourceAggregationLevel

// MARK: - GatewayAPI.ResourceAggregationLevel
extension GatewayAPI {
	public enum ResourceAggregationLevel: String, Codable, CaseIterable {
		case global = "Global"
		case vault = "Vault"
	}
}

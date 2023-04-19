import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.NetworkConfigurationResponse")
public typealias NetworkConfigurationResponse = GatewayAPI.NetworkConfigurationResponse

// MARK: - GatewayAPI.NetworkConfigurationResponse
extension GatewayAPI {
	public struct NetworkConfigurationResponse: Codable, Hashable {
		/** The logical id of the network */
		public private(set) var networkId: Int
		/** The logical name of the network */
		public private(set) var networkName: String
		public private(set) var wellKnownAddresses: NetworkConfigurationResponseWellKnownAddresses

		public init(networkId: Int, networkName: String, wellKnownAddresses: NetworkConfigurationResponseWellKnownAddresses) {
			self.networkId = networkId
			self.networkName = networkName
			self.wellKnownAddresses = wellKnownAddresses
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case networkId = "network_id"
			case networkName = "network_name"
			case wellKnownAddresses = "well_known_addresses"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(networkId, forKey: .networkId)
			try container.encode(networkName, forKey: .networkName)
			try container.encode(wellKnownAddresses, forKey: .wellKnownAddresses)
		}
	}
}

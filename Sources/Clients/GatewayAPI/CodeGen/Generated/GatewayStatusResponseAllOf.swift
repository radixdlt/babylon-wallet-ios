import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.GatewayStatusResponseAllOf")
public typealias GatewayStatusResponseAllOf = GatewayAPI.GatewayStatusResponseAllOf

// MARK: - GatewayAPI.GatewayStatusResponseAllOf
extension GatewayAPI {
	public struct GatewayStatusResponseAllOf: Codable, Hashable {
		public private(set) var releaseInfo: GatewayInfoResponseReleaseInfo

		public init(releaseInfo: GatewayInfoResponseReleaseInfo) {
			self.releaseInfo = releaseInfo
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case releaseInfo = "release_info"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(releaseInfo, forKey: .releaseInfo)
		}
	}
}

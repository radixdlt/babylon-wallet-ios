import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.GatewayInfoResponseReleaseInfo")
public typealias GatewayInfoResponseReleaseInfo = GatewayAPI.GatewayInfoResponseReleaseInfo

// MARK: - GatewayAPI.GatewayInfoResponseReleaseInfo
extension GatewayAPI {
	public struct GatewayInfoResponseReleaseInfo: Codable, Hashable {
		/** The release that is currently deployed to the Gateway API. */
		public private(set) var releaseVersion: String
		/** The Open API Schema version that was used to generate the API models. */
		public private(set) var openApiSchemaVersion: String

		public init(releaseVersion: String, openApiSchemaVersion: String) {
			self.releaseVersion = releaseVersion
			self.openApiSchemaVersion = openApiSchemaVersion
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case releaseVersion = "release_version"
			case openApiSchemaVersion = "open_api_schema_version"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(releaseVersion, forKey: .releaseVersion)
			try container.encode(openApiSchemaVersion, forKey: .openApiSchemaVersion)
		}
	}
}

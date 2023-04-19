import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.ScryptoSborValue")
public typealias ScryptoSborValue = GatewayAPI.ScryptoSborValue

// MARK: - GatewayAPI.ScryptoSborValue
extension GatewayAPI {
	public struct ScryptoSborValue: Codable, Hashable {
		public private(set) var rawHex: String
		public private(set) var rawJson: AnyCodable

		public init(rawHex: String, rawJson: AnyCodable) {
			self.rawHex = rawHex
			self.rawJson = rawJson
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case rawHex = "raw_hex"
			case rawJson = "raw_json"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(rawHex, forKey: .rawHex)
			try container.encode(rawJson, forKey: .rawJson)
		}
	}
}

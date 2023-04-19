import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.SborData")
public typealias SborData = GatewayAPI.SborData

// MARK: - GatewayAPI.SborData
extension GatewayAPI {
	public struct SborData: Codable, Hashable {
		/** The hex-encoded, raw SBOR-encoded data */
		public private(set) var dataHex: String
		/** An untyped JSON body representing the content of the SBOR data */
		public private(set) var dataJson: AnyCodable?

		public init(dataHex: String, dataJson: AnyCodable?) {
			self.dataHex = dataHex
			self.dataJson = dataJson
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case dataHex = "data_hex"
			case dataJson = "data_json"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(dataHex, forKey: .dataHex)
			try container.encode(dataJson, forKey: .dataJson)
		}
	}
}

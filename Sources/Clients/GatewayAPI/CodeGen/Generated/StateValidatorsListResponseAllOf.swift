import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateValidatorsListResponseAllOf")
public typealias StateValidatorsListResponseAllOf = GatewayAPI.StateValidatorsListResponseAllOf

// MARK: - GatewayAPI.StateValidatorsListResponseAllOf
extension GatewayAPI {
	public struct StateValidatorsListResponseAllOf: Codable, Hashable {
		public private(set) var validators: ValidatorCollection

		public init(validators: ValidatorCollection) {
			self.validators = validators
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case validators
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(validators, forKey: .validators)
		}
	}
}

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.InvalidRequestError")
public typealias InvalidRequestError = GatewayAPI.InvalidRequestError

// MARK: - GatewayAPI.InvalidRequestError
extension GatewayAPI {
	public struct InvalidRequestError: Codable, Hashable {
		/** The type of error. Each subtype may have its own additional structured fields. */
		public private(set) var type: String
		/** One or more validation errors which occurred when validating the request. */
		public private(set) var validationErrors: [ValidationErrorsAtPath]

		public init(type: String, validationErrors: [ValidationErrorsAtPath]) {
			self.type = type
			self.validationErrors = validationErrors
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case type
			case validationErrors = "validation_errors"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(type, forKey: .type)
			try container.encode(validationErrors, forKey: .validationErrors)
		}
	}
}

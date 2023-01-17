//
// InvalidRequestErrorAllOf.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import ClientPrelude
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.InvalidRequestErrorAllOf")
public typealias InvalidRequestErrorAllOf = GatewayAPI.InvalidRequestErrorAllOf

// MARK: - GatewayAPI.InvalidRequestErrorAllOf
public extension GatewayAPI {
	struct InvalidRequestErrorAllOf: Codable, Hashable {
		/** One or more validation errors which occurred when validating the request. */
		public private(set) var validationErrors: [ValidationErrorsAtPath]

		public init(validationErrors: [ValidationErrorsAtPath]) {
			self.validationErrors = validationErrors
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case validationErrors = "validation_errors"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(validationErrors, forKey: .validationErrors)
		}
	}
}

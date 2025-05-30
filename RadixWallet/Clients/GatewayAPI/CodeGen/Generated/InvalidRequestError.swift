//
// InvalidRequestError.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.InvalidRequestError")
typealias InvalidRequestError = GatewayAPI.InvalidRequestError

extension GatewayAPI {

struct InvalidRequestError: Codable, Hashable {

    /** The type of error. Each subtype may have its own additional structured fields. */
    private(set) var type: String
    /** One or more validation errors which occurred when validating the request. */
    private(set) var validationErrors: [ValidationErrorsAtPath]

    init(type: String, validationErrors: [ValidationErrorsAtPath]) {
        self.type = type
        self.validationErrors = validationErrors
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        case validationErrors = "validation_errors"
    }

    // Encodable protocol methods

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(validationErrors, forKey: .validationErrors)
    }
}

}

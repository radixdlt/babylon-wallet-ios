//
// InternalServerError.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.InternalServerError")
typealias InternalServerError = GatewayAPI.InternalServerError

extension GatewayAPI {

struct InternalServerError: Codable, Hashable {

    /** The type of error. Each subtype may have its own additional structured fields. */
    private(set) var type: String
    /** Gives an error type which occurred within the Gateway API when serving the request. */
    private(set) var exception: String
    /** Gives a human readable message - likely just a trace ID for reporting the error. */
    private(set) var cause: String

    init(type: String, exception: String, cause: String) {
        self.type = type
        self.exception = exception
        self.cause = cause
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        case exception
        case cause
    }

    // Encodable protocol methods

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(exception, forKey: .exception)
        try container.encode(cause, forKey: .cause)
    }
}

}

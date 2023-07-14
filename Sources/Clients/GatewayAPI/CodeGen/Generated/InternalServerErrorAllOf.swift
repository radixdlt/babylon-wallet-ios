//
// InternalServerErrorAllOf.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.InternalServerErrorAllOf")
public typealias InternalServerErrorAllOf = GatewayAPI.InternalServerErrorAllOf

extension GatewayAPI {

public struct InternalServerErrorAllOf: Codable, Hashable {

    /** Gives an error type which occurred within the Gateway API when serving the request. */
    public private(set) var exception: String
    /** Gives a human readable message - likely just a trace ID for reporting the error. */
    public private(set) var cause: String

    public init(exception: String, cause: String) {
        self.exception = exception
        self.cause = cause
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case exception
        case cause
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(exception, forKey: .exception)
        try container.encode(cause, forKey: .cause)
    }
}

}

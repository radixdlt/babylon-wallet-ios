//
// ModelErrorResponse.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.ModelErrorResponse")
public typealias ModelErrorResponse = GatewayAPI.ModelErrorResponse

extension GatewayAPI {

public struct ModelErrorResponse: Codable, Hashable {

    /** A human-readable error message. */
    public private(set) var message: String
    /** A numeric code corresponding to the given error type. */
    public private(set) var code: Int?
    public private(set) var details: GatewayError?
    /** A unique request identifier to be used when reporting errors, to allow correlation with the Gateway API's error logs. */
    public private(set) var traceId: String?

    public init(message: String, code: Int? = nil, details: GatewayError? = nil, traceId: String? = nil) {
        self.message = message
        self.code = code
        self.details = details
        self.traceId = traceId
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case message
        case code
        case details
        case traceId = "trace_id"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(message, forKey: .message)
        try container.encodeIfPresent(code, forKey: .code)
        try container.encodeIfPresent(details, forKey: .details)
        try container.encodeIfPresent(traceId, forKey: .traceId)
    }
}

}

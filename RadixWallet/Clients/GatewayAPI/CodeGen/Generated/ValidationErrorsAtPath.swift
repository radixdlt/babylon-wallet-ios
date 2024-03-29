//
// ValidationErrorsAtPath.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.ValidationErrorsAtPath")
public typealias ValidationErrorsAtPath = GatewayAPI.ValidationErrorsAtPath

extension GatewayAPI {

public struct ValidationErrorsAtPath: Codable, Hashable {

    public private(set) var path: String
    public private(set) var errors: [String]

    public init(path: String, errors: [String]) {
        self.path = path
        self.errors = errors
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case path
        case errors
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(path, forKey: .path)
        try container.encode(errors, forKey: .errors)
    }
}

}

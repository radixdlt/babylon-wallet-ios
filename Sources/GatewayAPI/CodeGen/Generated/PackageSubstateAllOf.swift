//
// PackageSubstateAllOf.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

public struct PackageSubstateAllOf: Codable, Hashable {

    /** The hex-encoded package code */
    public private(set) var codeHex: String

    public init(codeHex: String) {
        self.codeHex = codeHex
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case codeHex = "code_hex"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(codeHex, forKey: .codeHex)
    }
}


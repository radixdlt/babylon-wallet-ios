//
// PublicKeyEddsaEd25519AllOf.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.PublicKeyEddsaEd25519AllOf")
public typealias PublicKeyEddsaEd25519AllOf = GatewayAPI.PublicKeyEddsaEd25519AllOf

extension GatewayAPI {

public struct PublicKeyEddsaEd25519AllOf: Codable, Hashable {

    /** The hex-encoded compressed EdDSA Ed25519 public key (32 bytes) */
    public private(set) var keyHex: String

    public init(keyHex: String) {
        self.keyHex = keyHex
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case keyHex = "key_hex"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keyHex, forKey: .keyHex)
    }
}

}

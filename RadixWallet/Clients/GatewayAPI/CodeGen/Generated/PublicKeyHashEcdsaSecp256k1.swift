//
// PublicKeyHashEcdsaSecp256k1.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.PublicKeyHashEcdsaSecp256k1")
public typealias PublicKeyHashEcdsaSecp256k1 = GatewayAPI.PublicKeyHashEcdsaSecp256k1

extension GatewayAPI {

public struct PublicKeyHashEcdsaSecp256k1: Codable, Hashable {

    public private(set) var keyHashType: PublicKeyHashType
    /** Hex-encoded SHA-256 hash. */
    public private(set) var hashHex: String

    public init(keyHashType: PublicKeyHashType, hashHex: String) {
        self.keyHashType = keyHashType
        self.hashHex = hashHex
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case keyHashType = "key_hash_type"
        case hashHex = "hash_hex"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keyHashType, forKey: .keyHashType)
        try container.encode(hashHex, forKey: .hashHex)
    }
}

}

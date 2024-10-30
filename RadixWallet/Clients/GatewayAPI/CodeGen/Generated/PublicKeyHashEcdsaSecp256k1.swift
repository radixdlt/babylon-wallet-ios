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
typealias PublicKeyHashEcdsaSecp256k1 = GatewayAPI.PublicKeyHashEcdsaSecp256k1

extension GatewayAPI {

struct PublicKeyHashEcdsaSecp256k1: Codable, Hashable {

    private(set) var keyHashType: PublicKeyHashType
    /** Hex-encoded SHA-256 hash. */
    private(set) var hashHex: String

    init(keyHashType: PublicKeyHashType, hashHex: String) {
        self.keyHashType = keyHashType
        self.hashHex = hashHex
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case keyHashType = "key_hash_type"
        case hashHex = "hash_hex"
    }

    // Encodable protocol methods

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keyHashType, forKey: .keyHashType)
        try container.encode(hashHex, forKey: .hashHex)
    }
}

}

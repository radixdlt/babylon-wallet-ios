//
// ComponentMethodRoyalty.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.ComponentMethodRoyalty")
typealias ComponentMethodRoyalty = GatewayAPI.ComponentMethodRoyalty

extension GatewayAPI {

struct ComponentMethodRoyalty: Codable, Hashable {

    private(set) var methodName: String
    private(set) var royaltyAmount: RoyaltyAmount?

    init(methodName: String, royaltyAmount: RoyaltyAmount? = nil) {
        self.methodName = methodName
        self.royaltyAmount = royaltyAmount
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case methodName = "method_name"
        case royaltyAmount = "royalty_amount"
    }

    // Encodable protocol methods

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(methodName, forKey: .methodName)
        try container.encodeIfPresent(royaltyAmount, forKey: .royaltyAmount)
    }
}

}

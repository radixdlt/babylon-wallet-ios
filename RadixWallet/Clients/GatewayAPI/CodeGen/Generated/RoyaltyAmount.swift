//
// RoyaltyAmount.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.RoyaltyAmount")
typealias RoyaltyAmount = GatewayAPI.RoyaltyAmount

extension GatewayAPI {

struct RoyaltyAmount: Codable, Hashable {

    enum Unit: String, Codable, CaseIterable {
        case xrd = "XRD"
        case usd = "USD"
    }
    /** String-encoded decimal representing the amount of a related fungible resource. */
    private(set) var amount: String
    private(set) var unit: Unit

    init(amount: String, unit: Unit) {
        self.amount = amount
        self.unit = unit
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case amount
        case unit
    }

    // Encodable protocol methods

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(amount, forKey: .amount)
        try container.encode(unit, forKey: .unit)
    }
}

}

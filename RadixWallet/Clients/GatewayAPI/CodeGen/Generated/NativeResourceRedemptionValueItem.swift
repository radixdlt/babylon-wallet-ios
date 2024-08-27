//
// NativeResourceRedemptionValueItem.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.NativeResourceRedemptionValueItem")
public typealias NativeResourceRedemptionValueItem = GatewayAPI.NativeResourceRedemptionValueItem

extension GatewayAPI {

public struct NativeResourceRedemptionValueItem: Codable, Hashable {

    /** Bech32m-encoded human readable version of the address. */
    public private(set) var resourceAddress: String
    /** String-encoded decimal representing the amount of a related fungible resource. */
    public private(set) var amount: String?

    public init(resourceAddress: String, amount: String? = nil) {
        self.resourceAddress = resourceAddress
        self.amount = amount
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case resourceAddress = "resource_address"
        case amount
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(resourceAddress, forKey: .resourceAddress)
        try container.encodeIfPresent(amount, forKey: .amount)
    }
}

}
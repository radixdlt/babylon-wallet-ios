//
// AccountDepositPreValidationResourceSpecificBehaviourItem.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.AccountDepositPreValidationResourceSpecificBehaviourItem")
public typealias AccountDepositPreValidationResourceSpecificBehaviourItem = GatewayAPI.AccountDepositPreValidationResourceSpecificBehaviourItem

extension GatewayAPI {

public struct AccountDepositPreValidationResourceSpecificBehaviourItem: Codable, Hashable {

    /** Bech32m-encoded human readable version of the address. */
    public private(set) var resourceAddress: String
    public private(set) var allowsTryDeposit: Bool

    public init(resourceAddress: String, allowsTryDeposit: Bool) {
        self.resourceAddress = resourceAddress
        self.allowsTryDeposit = allowsTryDeposit
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case resourceAddress = "resource_address"
        case allowsTryDeposit = "allows_try_deposit"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(resourceAddress, forKey: .resourceAddress)
        try container.encode(allowsTryDeposit, forKey: .allowsTryDeposit)
    }
}

}

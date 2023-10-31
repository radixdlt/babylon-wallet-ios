//
// ValidatorsUptimeRequestAllOf.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.ValidatorsUptimeRequestAllOf")
public typealias ValidatorsUptimeRequestAllOf = GatewayAPI.ValidatorsUptimeRequestAllOf

extension GatewayAPI {

public struct ValidatorsUptimeRequestAllOf: Codable, Hashable {

    public private(set) var validatorAddresses: [String]?

    public init(validatorAddresses: [String]? = nil) {
        self.validatorAddresses = validatorAddresses
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case validatorAddresses = "validator_addresses"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(validatorAddresses, forKey: .validatorAddresses)
    }
}

}
